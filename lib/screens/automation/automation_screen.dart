import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/automation_rule.dart';
import '../../services/automation_service.dart';
import 'rule_editor_screen.dart';
import 'widgets/rule_card.dart';

/// Main automation rules tab showing all rules with management controls.
class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimController.forward();

    // Load rules on first build if not already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = context.read<AutomationService>();
      if (!svc.isLoaded) {
        svc.loadRules();
      }
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Automation',
          style: TextStyle(
            color: Color(0xFF1E2022),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Consumer<AutomationService>(
            builder: (_, svc, __) {
              if (svc.rules.isEmpty) return const SizedBox.shrink();
              final active = svc.activeCount;
              final total = svc.ruleCount;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: active > 0
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFF0F1F3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$active / $total active',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active > 0
                            ? const Color(0xFF388E3C)
                            : const Color(0xFF8A9099),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AutomationService>(
        builder: (context, svc, _) {
          if (!svc.isLoaded) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF388E3C),
                strokeWidth: 2.5,
              ),
            );
          }

          if (svc.rules.isEmpty) {
            return _buildEmptyState();
          }

          return _buildRulesList(svc);
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabAnimController,
          curve: Curves.easeOutBack,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _openEditor(context, null),
          backgroundColor: const Color(0xFF1F2E22),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text(
            'Add Rule',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F6),
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.auto_fix_high_rounded,
                size: 36,
                color: Color(0xFF00796B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Automation Rules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2022),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create rules to automatically respond to\nsensor changes in your terrarium.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _openEditor(context, null),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'Create First Rule',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2E22),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Rules list
  // ---------------------------------------------------------------------------
  Widget _buildRulesList(AutomationService svc) {
    final rules = svc.rules;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      itemCount: rules.length + 1, // +1 for the header
      itemBuilder: (context, index) {
        if (index == 0) return _buildListHeader(svc);
        final rule = rules[index - 1];
        return RuleCard(
          rule: rule,
          onTap: () => _openEditor(context, rule),
          onToggle: () => svc.toggleRule(rule.id),
          onDelete: () => svc.removeRule(rule.id),
        );
      },
    );
  }

  Widget _buildListHeader(AutomationService svc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            '${svc.ruleCount} rule${svc.ruleCount == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A9099),
            ),
          ),
          const Spacer(),
          if (svc.recentTriggers.isNotEmpty)
            GestureDetector(
              onTap: () => _showRecentTriggers(context, svc),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_rounded,
                        size: 14, color: Color(0xFFE65100)),
                    const SizedBox(width: 4),
                    Text(
                      '${svc.recentTriggers.length} triggered',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------
  Future<void> _openEditor(BuildContext context, AutomationRule? rule) async {
    final result = await Navigator.push<AutomationRule>(
      context,
      MaterialPageRoute(
        builder: (_) => RuleEditorScreen(existingRule: rule),
      ),
    );

    if (result != null && context.mounted) {
      final svc = context.read<AutomationService>();
      if (rule != null) {
        svc.updateRule(result);
      } else {
        svc.addRule(result);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Recent triggers sheet
  // ---------------------------------------------------------------------------
  void _showRecentTriggers(BuildContext context, AutomationService svc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      'Recent Triggers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2022),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        svc.clearTriggerHistory();
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: svc.recentTriggers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = svc.recentTriggers[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(t.rule.sensor.colorBg),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(t.rule.sensor.icon,
                                style: const TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.rule.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E2022),
                                  ),
                                ),
                                Text(
                                  t.summary,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _timeAgo(t.triggeredAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
