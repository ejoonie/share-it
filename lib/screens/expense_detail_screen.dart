import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../services/entry_chat_connection.dart';
import '../design_system/design_system.dart';
import '../models/expense_model.dart';
import '../providers/core_providers.dart';
import '../providers/expense_provider.dart';
import '../providers/session_provider.dart';
import '../repositories/entry_message_repository.dart';
import '../widgets/expense_form.dart';
import '../widgets/topic_picker.dart';

final entryMessageRepositoryProvider = Provider<EntryMessageRepository>(
  (ref) => EntryMessageRepository(ref.watch(apiClientProvider)),
);

class ExpenseDetailScreen extends ConsumerStatefulWidget {
  final ExpenseModel expense;
  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  ConsumerState<ExpenseDetailScreen> createState() =>
      _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends ConsumerState<ExpenseDetailScreen>
    with WidgetsBindingObserver {
  final _draft = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  List<EntryMessage> _messages = [];
  int? _cursor;
  EntryMessage? _editing;
  bool _loading = true;
  bool _hasLoaded = false;
  String? _draftBeforeEdit;
  final _pendingIds = <int>{};
  int _writeVersion = 0;
  bool _sending = false;
  bool _blocked = false;
  String? _error;
  bool _refreshPending = false;
  bool _accessRecheckPending = false;
  bool _live = false;
  int _accessVersion = 0;

  EntryMessageRepository get _repository =>
      ref.read(entryMessageRepositoryProvider);
  int get _entryId => widget.expense.id!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draft.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _live = false;
      });
      ref.invalidate(entryChatEventsProvider(_entryId));
      _requestRefresh();
    }
  }

  void _requestRefresh({bool recheckAccess = false}) {
    _accessRecheckPending = _accessRecheckPending || recheckAccess;
    _refreshPending = true;
    _drainRefresh();
  }

  void _drainRefresh() {
    if (!mounted ||
        _loading ||
        _sending ||
        (_blocked && !_accessRecheckPending)) {
      return;
    }
    if (_refreshPending) {
      _refreshPending = false;
      _accessRecheckPending = false;
      _load(preserveHistory: true);
    } else if (_pendingIds.isNotEmpty) {
      final id = _pendingIds.first;
      _pendingIds.remove(id);
      _syncMessage(id);
    }
  }

  void _finishEditing() {
    _editing = null;
    _draft.text = _draftBeforeEdit ?? '';
    _draftBeforeEdit = null;
  }

  bool _messageMissing(Object error) =>
      error is ApiException &&
      error.statusCode == 404 &&
      error.code == 'message_not_found';

  void _removeMessage(int id) {
    _messages.removeWhere((item) => item.id == id);
    if (_editing?.id == id) _finishEditing();
  }

  void _upsert(EntryMessage message) {
    _messages.removeWhere((item) => item.id == message.id);
    _messages.add(message);
    _messages.sort((a, b) => b.id.compareTo(a.id));
  }

  Future<void> _syncMessage(int id) async {
    final accessVersion = _accessVersion;
    final writeVersion = _writeVersion;
    setState(() {
      _loading = true;
    });
    try {
      final message = await _repository.get(_entryId, id);
      if (!mounted || accessVersion != _accessVersion) return;
      if (writeVersion != _writeVersion) {
        _pendingIds.add(id);
        return;
      }
      setState(() {
        _upsert(message);
      });
    } catch (error) {
      if (!mounted || accessVersion != _accessVersion) return;
      if (writeVersion != _writeVersion) {
        _pendingIds.add(id);
        return;
      }
      setState(() {
        if (_messageMissing(error)) {
          _removeMessage(id);
        } else {
          _error = _failure(error);
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _drainRefresh();
      }
    }
  }

  String _failure(Object error) {
    if (error is ApiException) {
      if ([401, 403, 404].contains(error.statusCode)) {
        _accessVersion++;
        _blocked = true;
        _messages = [];
        return 'This conversation is no longer available to you.';
      }
      if ([400, 422].contains(error.statusCode)) {
        return 'Please enter a message of up to 2,000 characters.';
      }
    }
    return 'Couldn’t connect. Please try again.';
  }

  Future<void> _load({bool older = false, bool preserveHistory = false}) async {
    final accessVersion = _accessVersion;
    final writeVersion = _writeVersion;
    if (older && (_loading || _cursor == null)) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      var page =
          await _repository.list(_entryId, beforeId: older ? _cursor : null);
      final records = [...page.messages];
      final targetCount = preserveHistory ? _messages.length : 0;
      while (records.length < targetCount && page.nextBeforeId != null) {
        page = await _repository.list(_entryId, beforeId: page.nextBeforeId);
        records.addAll(page.messages);
      }
      if (!mounted || accessVersion != _accessVersion) return;
      if (writeVersion != _writeVersion) {
        _refreshPending = true;
        return;
      }
      setState(() {
        _hasLoaded = true;
        _messages = older ? [..._messages, ...records] : records;
        _cursor = page.nextBeforeId;
        _blocked = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = _failure(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        _drainRefresh();
      }
    }
  }

  Future<void> _send() async {
    final body = _draft.text.trim();
    if (body.isEmpty ||
        body.runes.length > 2000 ||
        _sending ||
        !_hasLoaded ||
        _blocked) {
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final editing = _editing;
    _writeVersion++;
    try {
      final message = editing == null
          ? await _repository.send(_entryId, body)
          : await _repository.edit(_entryId, editing.id, body);
      if (!mounted || _blocked) return;
      setState(() {
        _writeVersion++;
        _upsert(message);
        if (editing == null) {
          _draft.clear();
        } else {
          _finishEditing();
        }
      });
      if (editing == null && _scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          if (_messageMissing(error) && editing != null) {
            _removeMessage(editing.id);
            _error = 'This message was deleted on another device.';
          } else {
            _error = _failure(error);
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
        _drainRefresh();
      }
    }
  }

  Future<void> _messageActions(EntryMessage message) async {
    if (_sending || !_hasLoaded || _blocked) return;
    final action = await showPiggySheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit message'),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete message'),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      setState(() {
        _draftBeforeEdit ??= _draft.text;
        _editing = message;
        _draft.text = message.body;
      });
      _focus.requestFocus();
    } else if (action == 'delete') {
      final confirmed = await showPiggyConfirmation(
        context: context,
        title: 'Delete message?',
        message: 'This message will be permanently removed.',
        confirmLabel: 'Delete',
        destructive: true,
      );
      if (confirmed != true || !mounted) return;
      setState(() {
        _sending = true;
      });
      _writeVersion++;
      try {
        await _repository.delete(_entryId, message.id);
        if (!mounted) return;
        setState(() {
          _writeVersion++;
          _removeMessage(message.id);
        });
      } catch (error) {
        if (mounted) {
          setState(() {
            if (_messageMissing(error)) {
              _removeMessage(message.id);
            } else {
              _error = _failure(error);
            }
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _sending = false;
          });
          _drainRefresh();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(entryChatEventsProvider(_entryId), (_, next) {
      if (next.isLoading || next.hasError) {
        setState(() {
          _live = false;
        });
        return;
      }
      final event = next.valueOrNull;
      if (event == null) return;
      setState(() {
        _live =
            event == ChatEvent.connected || (event.kind == 'changed' && _live);
      });
      if (event == ChatEvent.connected || event == ChatEvent.changed) {
        _requestRefresh(recheckAccess: event == ChatEvent.connected);
      } else if (event.messageId != null) {
        _pendingIds.add(event.messageId!);
        _drainRefresh();
      }
      if (event == ChatEvent.denied) {
        setState(() {
          _accessVersion++;
          _blocked = true;
          _messages = [];
          _error = 'This conversation is no longer available to you.';
        });
      }
    });
    final expense = ref
            .watch(expenseNotifierProvider)
            .monthlyExpenses
            .where((item) => item.id == _entryId)
            .firstOrNull ??
        widget.expense;
    final topics = ref.watch(myViewableTopicsProvider).valueOrNull ?? [];
    final topic = findTopicById(topics, expense.topicId);
    final userId = ref.watch(sessionNotifierProvider).data?.user?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          IconButton(
            tooltip: 'Refresh conversation',
            onPressed: _loading || _sending ? null : () => _load(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Edit transaction',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showPiggySheet<void>(
              context: context,
              builder: (_) => ExpenseForm(
                expense: expense,
                initYear: expense.occurredAt.year,
                initMonth: expense.occurredAt.month,
                initDay: expense.occurredAt.day,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: _scroll,
                reverse: true,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final message = _messages[index];
                          final mine = message.authorId == userId;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * .82,
                                ),
                                child: Material(
                                  color: mine
                                      ? PiggyColors.accentSoft
                                      : PiggyColors.card,
                                  borderRadius: BorderRadius.circular(18),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onLongPress: mine
                                        ? () => _messageActions(message)
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            mine ? 'You' : message.authorName,
                                            style: PiggyType.label,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            message.body,
                                            style: PiggyType.body
                                                .copyWith(height: 1.5),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${DateFormat('MMM d, h:mm a').format(message.createdAt.toLocal())}${message.updatedAt.isAfter(message.createdAt) ? ' · Edited' : ''}',
                                            style: PiggyType.metadata,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: _messages.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: PiggySurface(
                            color: expense.isIncome
                                ? PiggyColors.accentSoft
                                : PiggyColors.card,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.title.isEmpty
                                      ? 'Untitled transaction'
                                      : expense.title,
                                  style: PiggyType.pageTitle,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${expense.isIncome ? '+' : '−'}${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(expense.amountInDollars)}',
                                  style: PiggyType.summaryAmount,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  [
                                    DateFormat.yMMMd()
                                        .format(expense.occurredAt),
                                    if (topic != null) topic.title,
                                    if (expense.category?.isNotEmpty == true)
                                      expense.category!,
                                  ].join(' · '),
                                  style: PiggyType.caption,
                                ),
                                if (expense.content?.isNotEmpty == true) ...[
                                  const SizedBox(height: 12),
                                  Text(expense.content!, style: PiggyType.body),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _live
                                  ? 'Conversation · Live'
                                  : (_blocked
                                      ? 'Conversation'
                                      : 'Conversation · Connecting…'),
                              style: PiggyType.sectionTitle,
                            ),
                          ),
                        ),
                        if (_messages.isEmpty && !_loading && _error == null)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No messages yet.\nAsk a question or share a thought about this transaction.',
                              textAlign: TextAlign.center,
                              style: PiggyType.caption,
                            ),
                          ),
                        if (_loading && !_hasLoaded)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        if (_cursor != null && !_loading)
                          TextButton(
                            onPressed:
                                _sending ? null : () => _load(older: true),
                            child: const Text('Load earlier messages'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _error!,
                        style: PiggyType.caption
                            .copyWith(color: PiggyColors.error),
                      ),
                    ),
                    TextButton(
                      onPressed: _loading || _sending ? null : () => _load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            if (_editing != null)
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Editing message', style: PiggyType.caption),
                    ),
                    TextButton(
                      onPressed: _sending
                          ? null
                          : () => setState(() {
                                _finishEditing();
                              }),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _draft,
                      focusNode: _focus,
                      enabled: !_sending && !_blocked,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Write a message…',
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder(
                    valueListenable: _draft,
                    builder: (context, value, _) => IconButton.filled(
                      tooltip:
                          _editing == null ? 'Send message' : 'Save message',
                      onPressed: !_hasLoaded ||
                              _sending ||
                              _blocked ||
                              value.text.trim().isEmpty
                          ? null
                          : _send,
                      icon: _sending
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              _editing == null
                                  ? Icons.arrow_upward_rounded
                                  : Icons.check_rounded,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
