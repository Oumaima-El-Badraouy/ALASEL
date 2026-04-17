import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/responsive_content.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.peerId, required this.peerName});

  final String peerId;
  final String peerName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  String? conversationId;
  List<Map<String, dynamic>> messages = [];
  Timer? _poll;
  StreamSubscription<void>? _playSub;
  bool loading = true;

  String? _peerPhone;
  bool _loadingPhone = false;
  bool _recording = false;
  String? _playingMessageId;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final id = await ref.read(marketplaceRepositoryProvider).openConversation(widget.peerId);
    if (!mounted) return;
    setState(() {
      conversationId = id;
      loading = false;
    });
    if (id.isNotEmpty) {
      try {
        await ref.read(marketplaceRepositoryProvider).markConversationRead(id);
        ref.invalidate(inboxUnreadTotalProvider);
      } catch (_) {}
    }
    await _loadPeerPhone();
    await _refresh();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  Future<void> _loadPeerPhone() async {
    try {
      final m = await ref.read(marketplaceRepositoryProvider).peerContact(widget.peerId);
      final phone = m['phone'] ?? '';
      if (mounted) setState(() => _peerPhone = phone.isEmpty ? null : phone);
    } catch (_) {
      if (mounted) setState(() => _peerPhone = null);
    }
  }

  Future<void> _refresh() async {
    final id = conversationId;
    if (id == null || id.isEmpty) return;
    final list = await ref.read(marketplaceRepositoryProvider).listMessages(id);
    if (mounted) setState(() => messages = list);
  }

  Future<void> _sendText() async {
    final t = _text.text.trim();
    if (t.isEmpty || conversationId == null) return;
    await ref.read(marketplaceRepositoryProvider).sendMessage(conversationId!, text: t);
    _text.clear();
    await _refresh();
    ref.invalidate(inboxUnreadTotalProvider);
  }

  Future<void> _toggleRecording() async {
    final id = conversationId;
    if (id == null || id.isEmpty) return;
    if (_recording) {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path == null || !File(path).existsSync()) return;
      try {
        final bytes = await File(path).readAsBytes();
        final b64 = base64Encode(bytes);
        final url = 'data:audio/wav;base64,$b64';
        await ref.read(marketplaceRepositoryProvider).sendMessage(id, audioUrl: url);
        await _refresh();
        ref.invalidate(inboxUnreadTotalProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Audio: $e')));
        }
      } finally {
        try {
          await File(path).delete();
        } catch (_) {}
      }
      return;
    }
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autorisez le micro dans les paramètres.')),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/asel_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.wav),
        path: path,
      );
      if (mounted) setState(() => _recording = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enregistrement: $e')));
      }
    }
  }

  Future<void> _playAudio(Map<String, dynamic> m) async {
    final audioUrl = m['audioUrl'] as String?;
    if (audioUrl == null || audioUrl.isEmpty) return;
    final mid = m['id'] as String? ?? '';
    try {
      if (audioUrl.startsWith('data:')) {
        final i = audioUrl.indexOf(',');
        if (i < 0) return;
        final b64 = audioUrl.substring(i + 1);
        final bytes = base64Decode(b64);
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/play_$mid.wav');
        await f.writeAsBytes(bytes);
        setState(() => _playingMessageId = mid);
        await _playSub?.cancel();
        await _player.stop();
        await _player.play(DeviceFileSource(f.path));
        _playSub = _player.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _playingMessageId = null);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lecture: $e')));
      }
    }
  }

  Future<void> _callPeer() async {
    if (_peerPhone == null || _peerPhone!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro non renseigné pour ce contact.')),
        );
      }
      return;
    }
    final raw = _peerPhone!.replaceAll(RegExp(r'\s'), '');
    final uri = Uri.parse('tel:$raw');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Numéro : $_peerPhone')),
      );
    }
  }

  Future<void> _loadPhoneForCall() async {
    if (_peerPhone != null && _peerPhone!.isNotEmpty) {
      await _callPeer();
      return;
    }
    setState(() => _loadingPhone = true);
    try {
      final m = await ref.read(marketplaceRepositoryProvider).peerContact(widget.peerId);
      final phone = m['phone'] ?? '';
      if (!mounted) return;
      setState(() {
        _loadingPhone = false;
        _peerPhone = phone.isEmpty ? null : phone;
      });
      if (phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro non renseigné pour ce contact.')),
        );
        return;
      }
      await _callPeer();
    } catch (e) {
      if (mounted) {
        setState(() => _loadingPhone = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _playSub?.cancel();
    _text.dispose();
    unawaited(_recorder.dispose());
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authNotifierProvider).user;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final paddingBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.sand,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.peerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_peerPhone != null && _peerPhone!.isNotEmpty)
              Text(
                _peerPhone!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Appeler',
            onPressed: _loadingPhone ? null : _loadPhoneForCall,
            icon: _loadingPhone
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.call_outlined),
          ),
        ],
      ),
      body: ResponsiveContent(
        maxWidth: 560,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final m = messages[i];
                        final mine = m['senderId'] == me?.id;
                        final text = m['text'] as String? ?? '';
                        final audioUrl = m['audioUrl'] as String?;
                        final hasAudio = audioUrl != null && audioUrl.isNotEmpty;
                        final mid = m['id'] as String? ?? '$i';

                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: mine ? AppColors.deepBlue : AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                            ),
                            child: hasAudio
                                ? InkWell(
                                    onTap: () => _playAudio(m),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _playingMessageId == mid ? Icons.stop_circle_outlined : Icons.play_circle_fill_outlined,
                                          size: 28,
                                          color: mine ? Colors.white : AppColors.ink,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            _playingMessageId == mid ? 'Lecture…' : 'Message vocal',
                                            style: TextStyle(color: mine ? Colors.white : AppColors.ink),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    text,
                                    style: TextStyle(color: mine ? Colors.white : AppColors.ink),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  Material(
                    color: AppColors.white,
                    elevation: 8,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 8,
                        right: 8,
                        top: 8,
                        bottom: bottomInset > 0 ? bottomInset : paddingBottom + 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton.filledTonal(
                            tooltip: _recording ? 'Arrêter et envoyer' : 'Enregistrer un vocal',
                            onPressed: _toggleRecording,
                            style: IconButton.styleFrom(
                              backgroundColor: _recording
                                  ? AppColors.terracotta.withValues(alpha: 0.35)
                                  : null,
                            ),
                            icon: Icon(_recording ? Icons.stop : Icons.mic_none_rounded),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _text,
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Écrire un message…',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onSubmitted: (_) => _sendText(),
                            ),
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            onPressed: _sendText,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.all(14),
                              minimumSize: const Size(48, 48),
                            ),
                            child: const Icon(Icons.send_rounded, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
