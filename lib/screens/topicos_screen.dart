import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/defaults.dart';
import '../core/navigation/app_tab.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/amount_parser.dart';
import '../models/activity.dart';
import '../models/topic.dart';
import '../providers/activities_provider.dart';
import '../providers/balance_provider.dart';
import '../providers/main_tab_provider.dart';
import '../providers/topics_provider.dart';
import '../providers/trash_provider.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/new_topic_template_card.dart';
import '../widgets/swipeable_topic_card.dart';
import 'topic_detail_screen.dart';

class TopicosScreen extends ConsumerStatefulWidget {
  const TopicosScreen({super.key});

  @override
  ConsumerState<TopicosScreen> createState() => _TopicosScreenState();
}

class _TopicosScreenState extends ConsumerState<TopicosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(topicsProvider.notifier).ensureDefault());
    });
  }

  void _openTopic(Topic topic) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, __, ___) => TopicDetailScreen(topic: topic),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _createTopic(String name) async {
    await ref.read(topicsProvider.notifier).add(name);
    if (mounted) {
      ref.read(tutorialControllerProvider).onTopicCreated(context);
    }
  }

  Future<void> _handleDelete(Topic topic) async {
    if (TopicsNotifier.isDefault(topic)) return;
    await ref.read(trashProvider.notifier).moveTopicToTrash(topic);
    ref.read(undoControllerProvider).show();
  }

  Widget _topicCard(Topic topic, List<Activity> activities, double rate, {Key? cardKey}) {
    final topicActivities = activities
        .where((a) => a.topicId == topic.id)
        .toList(growable: false);
    final isDefault = TopicsNotifier.isDefault(topic);
    return SwipeableTopicCard(
      cardKey: cardKey,
      item: topic,
      activityCount: topicActivities.length,
      extremes: TopicExtremes.fromActivities(
        topicActivities,
        rate: rate,
      ),
      isDefault: isDefault,
      deletable: !isDefault,
      onPress: _openTopic,
      onDelete: _handleDelete,
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = ref.watch(topicsProvider);
    final activities = ref.watch(activitiesProvider);
    final rate = ref.watch(effectiveRateProvider);
    final activeTab = ref.watch(mainTabProvider);

    if (activeTab == AppTab.topicos.tabIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final tutorialCtrl = ref.read(tutorialControllerProvider);
        if (!tutorialCtrl.isTourRunning) {
          tutorialCtrl.showScreenTutorial(context, 2);
        }
      });
    }

    Topic? defaultTopic;
    final otherTopics = <Topic>[];
    for (final topic in topics) {
      if (TopicsNotifier.isDefault(topic)) {
        defaultTopic ??= topic;
      } else {
        otherTopics.add(topic);
      }
    }
    defaultTopic ??= const Topic(
      id: Defaults.defaultTopicId,
      name: Defaults.defaultTopicName,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TÓPICOS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.read(tutorialControllerProvider).startInteractiveTopicTour(context),
                    icon: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.textSecondary),
                    tooltip: 'Ver tutorial de esta pantalla',
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                'Mis categorías',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              const _SectionLabel('POR DEFECTO'),
              const SizedBox(height: 10),
              _topicCard(defaultTopic, activities, rate, cardKey: TutorialKeys.topicDefaultCard),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Color(0xFFE8E8E8),
                ),
              ),
              const _SectionLabel('TUS TÓPICOS'),
              const SizedBox(height: 10),
              NewTopicTemplateCard(
                key: TutorialKeys.topicAdd,
                onConfirm: _createTopic,
              ),
              if (otherTopics.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...otherTopics.asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final topic = entry.value;
                    return _topicCard(
                      topic,
                      activities,
                      rate,
                      cardKey: index == 0 ? TutorialKeys.firstCustomTopicCard : null,
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      ),
    );
  }
}
