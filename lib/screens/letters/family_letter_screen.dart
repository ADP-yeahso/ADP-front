import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_data.dart';
import '../../data/auth_session.dart';
import '../../services/api_service.dart';

class FamilyLetterScreen extends StatefulWidget {
  const FamilyLetterScreen({super.key, this.api});

  final ApiService? api;

  @override
  State<FamilyLetterScreen> createState() => _FamilyLetterScreenState();
}

class _FamilyLetterScreenState extends State<FamilyLetterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final ApiService _api;
  late final bool _ownsApi;
  List<Map<String, dynamic>> _letters = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ownsApi = widget.api == null;
    _api = widget.api ?? ApiService();
    _tabs = TabController(length: 2, vsync: this)..addListener(_tabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_tabChanged)
      ..dispose();
    if (_ownsApi) _api.close();
    super.dispose();
  }

  void _tabChanged() {
    if (!_tabs.indexIsChanging) _load();
  }

  Future<void> _load() async {
    final tokens = context.read<AuthSession>().tokens;
    final groupId = context.read<AppData>().group.id;
    if (tokens == null || groupId <= 0) {
      setState(() {
        _loading = false;
        _error = '가족 그룹에 로그인한 뒤 편지함을 이용해주세요.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final letters = await LetterApi(
        _api,
      ).list(tokens, groupId, sent: _tabs.index == 1);
      if (mounted) setState(() => _letters = letters);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _compose() async {
    final data = context.read<AppData>();
    final tokens = context.read<AuthSession>().tokens;
    if (tokens == null || data.group.id <= 0) return;
    final controller = TextEditingController();
    String? receiverId;
    var sending = false;
    final navigator = Navigator.of(context);
    final localizations = MaterialLocalizations.of(context);
    final route = ModalBottomSheetRoute<bool>(
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      isScrollControlled: true,
      showDragHandle: true,
      barrierLabel: localizations.scrimLabel,
      barrierOnTapHint: localizations.scrimOnTapHint(
        localizations.bottomSheetLabel,
      ),
      modalBarrierColor: Theme.of(context).bottomSheetTheme.modalBarrierColor,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '가족에게 편지 쓰기',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: receiverId,
                decoration: const InputDecoration(
                  labelText: '받는 사람',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('가족 모두')),
                  for (final user in data.users)
                    if (!data.isCurrentUser(user.id))
                      DropdownMenuItem(value: user.id, child: Text(user.name)),
                ],
                onChanged: sending
                    ? null
                    : (value) => setSheetState(() => receiverId = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 4,
                maxLines: 7,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: '가족에게 전할 마음을 적어주세요.',
                  border: OutlineInputBorder(),
                ),
              ),
              FilledButton(
                onPressed: sending
                    ? null
                    : () async {
                        final content = controller.text.trim();
                        if (content.isEmpty) return;
                        setSheetState(() => sending = true);
                        try {
                          await LetterApi(_api).send(
                            tokens,
                            groupId: data.group.id,
                            receiverUserId: receiverId,
                            content: content,
                          );
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext, true);
                          }
                        } on ApiException catch (error) {
                          if (!sheetContext.mounted) return;
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                          setSheetState(() => sending = false);
                        }
                      },
                child: Text(sending ? '보내는 중...' : '편지 보내기'),
              ),
            ],
          ),
        ),
      ),
    );
    final sent = await navigator.push(route);
    // Navigator.push completes as soon as pop starts. Keep the controller and
    // inherited dependencies alive until the sheet's reverse transition has
    // fully detached it from the widget tree.
    await route.completed;
    controller.dispose();
    if (sent == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('편지를 보냈어요.')));
      _tabs.animateTo(1);
      await _load();
    }
  }

  Future<void> _open(Map<String, dynamic> letter) async {
    final tokens = context.read<AuthSession>().tokens;
    if (tokens == null) return;
    try {
      final detail = await LetterApi(_api).detail(tokens, letter['id'] as int);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_personName(detail['sender_user_id']?.toString())),
          content: Text(detail['content']?.toString() ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  String _personName(String? id) {
    if (id == null) return '가족';
    final data = context.read<AppData>();
    if (data.isCurrentUser(id)) return '나';
    for (final user in data.users) {
      if (user.id == id) return user.name;
    }
    return '가족';
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_letters.isEmpty) {
      return Center(
        child: Text(_tabs.index == 0 ? '받은 편지가 없어요.' : '보낸 편지가 없어요.'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _letters.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final letter = _letters[index];
          final sender = _personName(letter['sender_user_id']?.toString());
          final receiver = letter['receiver_user_id'] == null
              ? '가족 모두'
              : _personName(letter['receiver_user_id']?.toString());
          final unread = _tabs.index == 0 && letter['is_read'] == false;
          return Card(
            child: ListTile(
              leading: Icon(
                unread ? Icons.mark_email_unread : Icons.mail_outline,
                color: const Color(0xFF386629),
              ),
              title: Text(_tabs.index == 0 ? sender : receiver),
              subtitle: Text(
                letter['content']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _open(letter),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가족 편지함'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: '받은 편지'),
            Tab(text: '보낸 편지'),
          ],
        ),
      ),
      body: _body(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('편지 쓰기'),
      ),
    );
  }
}
