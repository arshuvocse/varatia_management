part of 'tenant_reference_pages.dart';

class TenantTutorTeachLearnPage extends StatefulWidget {
  const TenantTutorTeachLearnPage({super.key});

  @override
  State<TenantTutorTeachLearnPage> createState() =>
      _TenantTutorTeachLearnPageState();
}

class _TenantTutorTeachLearnPageState extends State<TenantTutorTeachLearnPage> {
  late final TextEditingController _searchController;
  late final List<_TutorPostData> _posts;
  final TenantTutorApiService _tutorApiService = TenantTutorApiService();

  _TutorPostType? _activeType;
  String? _selectedSubjectEn;
  String? _selectedAreaEn;
  bool _verifiedOnly = false;
  bool _savedOnly = false;
  bool _isLoadingPosts = true;
  bool _isSubmittingPost = false;
  String? _apiError;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _posts = <_TutorPostData>[];
    _loadPosts();
  }

  @override
  void dispose() {
    _tutorApiService.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    if (mounted) {
      setState(() {
        _isLoadingPosts = true;
        _apiError = null;
      });
    }

    try {
      final result = await _tutorApiService.getPosts(limit: 50);
      if (!mounted) {
        return;
      }

      setState(() {
        _posts
          ..clear()
          ..addAll(result.posts.map(_TutorPostData.fromApi));
        _isLoadingPosts = false;
      });
    } on TenantTutorApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _apiError = error.message;
        _isLoadingPosts = false;
      });
    }
  }

  List<_TutorPostData> get _filteredPosts {
    final query = _searchController.text.trim().toLowerCase();

    return _posts
        .where((post) {
          if (_activeType != null && post.type != _activeType) {
            return false;
          }
          if (_selectedSubjectEn != null &&
              _selectedSubjectEn != 'All Subjects' &&
              !post.subjectEn.toLowerCase().contains('all') &&
              !post.subjectBn.contains('সকল') &&
              !post.subjectEn.toLowerCase().contains(
                _selectedSubjectEn!.toLowerCase(),
              ) &&
              !post.subjectBn.toLowerCase().contains(
                _selectedSubjectEn!.toLowerCase(),
              )) {
            return false;
          }
          if (_selectedAreaEn != null && post.areaEn != _selectedAreaEn) {
            return false;
          }
          if (_verifiedOnly && !post.verified) {
            return false;
          }
          if (_savedOnly &&
              !context.read<TenantExperienceViewModel>().isPostSaved(
                post.id,
                'TutorPost',
              )) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }

          final searchableText = [
            post.name,
            post.roleBn,
            post.roleEn,
            post.subjectBn,
            post.subjectEn,
            post.areaBn,
            post.areaEn,
            post.priceBn,
            post.priceEn,
            post.availabilityBn,
            post.availabilityEn,
            post.descriptionBn,
            post.descriptionEn,
          ].join(' ').toLowerCase();

          return searchableText.contains(query);
        })
        .toList(growable: false);
  }

  int get _verifiedTutorCount => _posts
      .where((post) => post.type == _TutorPostType.tutor && post.verified)
      .length;

  int get _nearbyPostCount => _posts.length;

  String get _averageRating {
    final ratings = _posts
        .map((post) => double.tryParse(post.rating))
        .whereType<double>()
        .toList(growable: false);
    if (ratings.isEmpty) {
      return '0.0';
    }

    final total = ratings.fold<double>(0, (sum, rating) => sum + rating);
    return (total / ratings.length).toStringAsFixed(1);
  }

  void _showStatus(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearFilters() {
    setState(() {
      _activeType = null;
      _selectedSubjectEn = null;
      _selectedAreaEn = null;
      _verifiedOnly = false;
      _savedOnly = false;
      _searchController.clear();
    });
  }

  void _selectSubject(_TutorSubjectData subject) {
    setState(() {
      _selectedSubjectEn = _selectedSubjectEn == subject.labelEn
          ? null
          : subject.labelEn;
    });
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_TutorFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TutorFilterSheet(
        initialType: _activeType,
        initialSubjectEn: _selectedSubjectEn,
        initialAreaEn: _selectedAreaEn,
        initialVerifiedOnly: _verifiedOnly,
        initialSavedOnly: _savedOnly,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _activeType = result.type;
      _selectedSubjectEn = result.subjectEn;
      _selectedAreaEn = result.areaEn;
      _verifiedOnly = result.verifiedOnly;
      _savedOnly = result.savedOnly;
    });
  }

  Future<void> _openComposer(_TutorPostType type) async {
    if (_isSubmittingPost) {
      return;
    }

    final session = await AuthSessionService().readSession();
    if (!mounted) return;

    if (session == null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const TenantTutorWelcomePage()),
      );
      return;
    }

    final createdPost = await Navigator.of(context).push<_TutorPostData>(
      MaterialPageRoute<_TutorPostData>(
        builder: (_) => _TutorPostComposerPage(initialType: type),
      ),
    );

    if (createdPost == null || !mounted) {
      return;
    }

    setState(() => _isSubmittingPost = true);

    try {
      final result = await _tutorApiService.createPost(
        input: createdPost.toCreatePostInput(),
      );

      if (!mounted) {
        return;
      }

      final apiPost = result.post;
      final syncedPost = apiPost == null || apiPost.subject.en.trim().isEmpty
          ? createdPost
          : _TutorPostData.fromApi(apiPost);

      setState(() {
        _posts.insert(0, syncedPost);
        _activeType = syncedPost.type;
        _selectedSubjectEn = null;
        _selectedAreaEn = null;
        _verifiedOnly = false;
        _savedOnly = false;
        _searchController.clear();
        _apiError = null;
      });

      _showStatus(result.message);
    } on TenantTutorApiException catch (error) {
      if (mounted) {
        _showStatus(error.message);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingPost = false);
      }
    }
  }

  Future<void> _openPostDetails(_TutorPostData post) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _TutorPostDetailsPage(
          post: post,
          isSaved: context.read<TenantExperienceViewModel>().isPostSaved(
            post.id,
            'TutorPost',
          ),
          onToggleSaved: () {
            context.read<TenantExperienceViewModel>().toggleSavedPost(
              post.id,
              'TutorPost',
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPosts = _filteredPosts;

    return _DetailScaffold(
      title: 'Tutor Teach / Learn',
      trailing: IconButton(
        onPressed: _openFilterSheet,
        icon: const Icon(Icons.tune_rounded),
      ),
      bottomAction: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSubmittingPost
                  ? null
                  : () => _openComposer(_TutorPostType.request),
              icon: const Icon(Icons.person_search_rounded),
              label: Text(context.tr(bn: 'শিক্ষক চাই', en: 'Need Tutor')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isSubmittingPost
                  ? null
                  : () => _openComposer(_TutorPostType.tutor),
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(
                _isSubmittingPost
                    ? context.tr(bn: 'পাঠানো হচ্ছে', en: 'Posting')
                    : context.tr(bn: 'অফার দিন', en: 'Offer'),
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TutorHeroBanner(
            verifiedTutorCount: _verifiedTutorCount,
            nearbyPostCount: _nearbyPostCount,
            averageRating: _averageRating,
            onTeach: () => _openComposer(_TutorPostType.tutor),
            onLearn: () => _openComposer(_TutorPostType.request),
          ),
          const SizedBox(height: 12),
          const ProfileCompletionMeterCard(compact: true),
          if (_isLoadingPosts) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 2),
          ],
          if (_apiError != null) ...[
            const SizedBox(height: 12),
            _TutorApiStatusTile(message: _apiError!, onRetry: _loadPosts),
          ],
          const SizedBox(height: 16),
          _TutorSearchPanel(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            onClear: () => setState(_searchController.clear),
          ),
          const SizedBox(height: 16),
          Row(
            children: _tutorIntentOptions
                .map(
                  (option) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: option == _tutorIntentOptions.last ? 0 : 12,
                      ),
                      child: _TutorIntentCard(
                        option: option,
                        isSelected: _activeType == option.type,
                        onTap: () => _openComposer(option.type),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          _TutorSectionHeader(
            title: context.tr(bn: 'জনপ্রিয় বিষয়', en: 'Popular Subjects'),
            actionLabel: context.tr(bn: 'সব', en: 'All'),
            onAction: _clearFilters,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tutorSubjects
                  .map(
                    (subject) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _TutorSubjectChip(
                        subject: subject,
                        isSelected: _selectedSubjectEn == subject.labelEn,
                        onTap: () => _selectSubject(subject),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          if (_hasActiveTutorFilters) ...[
            const SizedBox(height: 12),
            _TutorActiveFilterBar(onClear: _clearFilters),
          ],
          const SizedBox(height: 18),
          _TutorSectionHeader(
            title: context.tr(bn: 'কাছাকাছি পোস্ট', en: 'Nearby Posts'),
            actionLabel: context.tr(bn: 'সব দেখুন', en: 'See All'),
            onAction: _clearFilters,
          ),
          const SizedBox(height: 10),
          if (filteredPosts.isEmpty)
            _TutorEmptyState(onClear: _clearFilters)
          else
            ...filteredPosts.map(
              (post) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TutorPostCard(
                  post: post,
                  isSaved: context
                      .watch<TenantExperienceViewModel>()
                      .isPostSaved(post.id, 'TutorPost'),
                  onTap: () => _openPostDetails(post),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool get _hasActiveTutorFilters {
    return _searchController.text.trim().isNotEmpty ||
        _activeType != null ||
        _selectedSubjectEn != null ||
        _selectedAreaEn != null ||
        _verifiedOnly ||
        _savedOnly;
  }
}

class _TutorHeroBanner extends StatelessWidget {
  const _TutorHeroBanner({
    required this.verifiedTutorCount,
    required this.nearbyPostCount,
    required this.averageRating,
    required this.onTeach,
    required this.onLearn,
  });

  final int verifiedTutorCount;
  final int nearbyPostCount;
  final String averageRating;
  final VoidCallback onTeach;
  final VoidCallback onLearn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FDF4), Color(0xFFF8FAFC), Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: const Color(0xFFD1FAE5)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        bn: 'শিক্ষক দিচ্ছি / নিচ্ছি',
                        en: 'Tutor Teach / Learn',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(
                        bn: 'এলাকার যাচাইকৃত শিক্ষক ও শিক্ষার্থী পোস্ট দেখুন',
                        en: 'Find verified tutors and learning requests nearby',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TutorHeroStat(
                icon: Icons.verified_rounded,
                iconColor: const Color(0xFF059669),
                label: context.tr(bn: 'যাচাইকৃত শিক্ষক', en: 'Verified'),
                value: context.digitsText(verifiedTutorCount),
              ),
              _TutorHeroStat(
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFF4F46E5),
                label: context.tr(bn: 'আপনার এলাকায়', en: 'Near you'),
                value: context.digitsText(nearbyPostCount),
              ),
              _TutorHeroStat(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFD97706),
                label: context.tr(bn: 'রেটিং', en: 'Rating'),
                value: context.isBangla
                    ? context.digitsText(num.tryParse(averageRating) ?? 0)
                    : averageRating,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TutorHeroAction(
                  icon: Icons.edit_note_rounded,
                  iconColor: const Color(0xFF059669),
                  label: context.tr(bn: 'শিক্ষক দিচ্ছি', en: 'I teach'),
                  onTap: onTeach,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TutorHeroAction(
                  icon: Icons.person_search_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  label: context.tr(bn: 'শিক্ষক নিচ্ছি', en: 'I want tutor'),
                  onTap: onLearn,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TutorHeroStat extends StatelessWidget {
  const _TutorHeroStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 5),
          Text(
            '$value $label',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorHeroAction extends StatelessWidget {
  const _TutorHeroAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: AppShadows.subtle,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorSearchPanel extends StatelessWidget {
  const _TutorSearchPanel({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.tr(
          bn: 'বিষয়, ক্লাস বা এলাকা দিয়ে খুঁজুন',
          en: 'Search subject, class, or area',
        ),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? const Icon(Icons.mic_none_rounded)
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _TutorIntentCard extends StatelessWidget {
  const _TutorIntentCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _TutorIntentOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? option.color.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? option.color : AppColors.border,
              width: isSelected ? 1.3 : 1,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: option.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(option.icon, color: option.color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr(bn: option.titleBn, en: option.titleEn),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(bn: option.subtitleBn, en: option.subtitleEn),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 11.5, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorSectionHeader extends StatelessWidget {
  const _TutorSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _TutorSubjectChip extends StatelessWidget {
  const _TutorSubjectChip({
    required this.subject,
    required this.isSelected,
    required this.onTap,
  });

  final _TutorSubjectData subject;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? subject.color
                : subject.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? subject.color
                  : subject.color.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                subject.icon,
                color: isSelected ? Colors.white : subject.color,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                context.tr(bn: subject.labelBn, en: subject.labelEn),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorActiveFilterBar extends StatelessWidget {
  const _TutorActiveFilterBar({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr(
                bn: 'ফিল্টার করা রেজাল্ট দেখানো হচ্ছে',
                en: 'Showing filtered results',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(context.tr(bn: 'রিসেট', en: 'Reset')),
          ),
        ],
      ),
    );
  }
}

class _TutorApiStatusTile extends StatelessWidget {
  const _TutorApiStatusTile({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFC2410C),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF9A3412),
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(context.tr(bn: 'আবার চেষ্টা', en: 'Retry')),
          ),
        ],
      ),
    );
  }
}

class _TutorEmptyState extends StatelessWidget {
  const _TutorEmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      child: Column(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.tr(bn: 'কোনো পোস্ট পাওয়া যায়নি', en: 'No posts found'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            context.tr(
              bn: 'সার্চ বা ফিল্টার বদলে আবার চেষ্টা করুন।',
              en: 'Adjust search or filters and try again.',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onClear,
            child: Text(context.tr(bn: 'সব পোস্ট দেখুন', en: 'Show all posts')),
          ),
        ],
      ),
    );
  }
}

class _TutorPostCard extends StatelessWidget {
  const _TutorPostCard({
    required this.post,
    required this.isSaved,
    required this.onTap,
  });

  final _TutorPostData post;
  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [post.color, post.color.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: post.color.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      post.name.characters.first,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                post.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (post.verified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF16A34A),
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.tr(bn: post.roleBn, en: post.roleEn),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _TutorStatusBadge(
                        label: context.tr(bn: post.badgeBn, en: post.badgeEn),
                        color: post.color,
                      ),
                      const SizedBox(height: 5),
                      _TutorStatusBadge(
                        label: context.tr(
                          bn: post.fulfillmentLabelBn(),
                          en: post.fulfillmentLabelEn(),
                        ),
                        color: post.fulfillmentColor(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TutorInfoLine(
                      icon: Icons.menu_book_rounded,
                      label: context.tr(bn: post.subjectBn, en: post.subjectEn),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TutorInfoLine(
                      icon: Icons.place_rounded,
                      label: context.tr(bn: post.areaBn, en: post.areaEn),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TutorInfoLine(
                      icon: Icons.payments_rounded,
                      label: context.tr(bn: post.priceBn, en: post.priceEn),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TutorInfoLine(
                      icon: Icons.schedule_rounded,
                      label: context.tr(
                        bn: post.availabilityBn,
                        en: post.availabilityEn,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          post.rating,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSaved) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bookmark_rounded,
                        color: Color(0xFFE11D48),
                        size: 16,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: post.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: post.color,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          context.tr(bn: 'মেসেজ', en: 'Message'),
                          style: TextStyle(
                            color: post.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorStatusBadge extends StatelessWidget {
  const _TutorStatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TutorInfoLine extends StatelessWidget {
  const _TutorInfoLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 17),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorFilterResult {
  const _TutorFilterResult({
    required this.type,
    required this.subjectEn,
    required this.areaEn,
    required this.verifiedOnly,
    required this.savedOnly,
  });

  final _TutorPostType? type;
  final String? subjectEn;
  final String? areaEn;
  final bool verifiedOnly;
  final bool savedOnly;
}

class _TutorFilterSheet extends StatefulWidget {
  const _TutorFilterSheet({
    required this.initialType,
    required this.initialSubjectEn,
    required this.initialAreaEn,
    required this.initialVerifiedOnly,
    required this.initialSavedOnly,
  });

  final _TutorPostType? initialType;
  final String? initialSubjectEn;
  final String? initialAreaEn;
  final bool initialVerifiedOnly;
  final bool initialSavedOnly;

  @override
  State<_TutorFilterSheet> createState() => _TutorFilterSheetState();
}

class _TutorFilterSheetState extends State<_TutorFilterSheet> {
  late _TutorPostType? _type = widget.initialType;
  late String? _subjectEn = widget.initialSubjectEn;
  late String? _areaEn = widget.initialAreaEn;
  late bool _verifiedOnly = widget.initialVerifiedOnly;
  late bool _savedOnly = widget.initialSavedOnly;

  void _apply() {
    Navigator.of(context).pop(
      _TutorFilterResult(
        type: _type,
        subjectEn: _subjectEn,
        areaEn: _areaEn,
        verifiedOnly: _verifiedOnly,
        savedOnly: _savedOnly,
      ),
    );
  }

  void _clear() {
    Navigator.of(context).pop(
      const _TutorFilterResult(
        type: null,
        subjectEn: null,
        areaEn: null,
        verifiedOnly: false,
        savedOnly: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.card,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(bn: 'ফিল্টার', en: 'Filters'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _TutorFilterTitle(
                  title: context.tr(bn: 'পোস্ট টাইপ', en: 'Post type'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(context.tr(bn: 'সব', en: 'All')),
                      selected: _type == null,
                      onSelected: (_) => setState(() => _type = null),
                    ),
                    ChoiceChip(
                      label: Text(context.tr(bn: 'শিক্ষক', en: 'Tutor')),
                      selected: _type == _TutorPostType.tutor,
                      onSelected: (_) =>
                          setState(() => _type = _TutorPostType.tutor),
                    ),
                    ChoiceChip(
                      label: Text(
                        context.tr(bn: 'শিক্ষক চাই', en: 'Need Tutor'),
                      ),
                      selected: _type == _TutorPostType.request,
                      onSelected: (_) =>
                          setState(() => _type = _TutorPostType.request),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _TutorFilterTitle(
                  title: context.tr(bn: 'বিষয়', en: 'Subject'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(context.tr(bn: 'সব', en: 'All')),
                      selected: _subjectEn == null,
                      onSelected: (_) => setState(() => _subjectEn = null),
                    ),
                    ..._tutorSubjects.map(
                      (subject) => ChoiceChip(
                        label: Text(
                          context.tr(bn: subject.labelBn, en: subject.labelEn),
                        ),
                        selected: _subjectEn == subject.labelEn,
                        onSelected: (_) =>
                            setState(() => _subjectEn = subject.labelEn),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _TutorFilterTitle(
                  title: context.tr(bn: 'এলাকা', en: 'Area'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(context.tr(bn: 'সব', en: 'All')),
                      selected: _areaEn == null,
                      onSelected: (_) => setState(() => _areaEn = null),
                    ),
                    ..._tutorAreas.map(
                      (area) => ChoiceChip(
                        label: Text(
                          context.tr(bn: area.labelBn, en: area.labelEn),
                        ),
                        selected: _areaEn == area.labelEn,
                        onSelected: (_) =>
                            setState(() => _areaEn = area.labelEn),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      selected: _verifiedOnly,
                      label: Text(
                        context.tr(bn: 'শুধু যাচাইকৃত', en: 'Verified only'),
                      ),
                      avatar: const Icon(Icons.verified_rounded, size: 18),
                      onSelected: (value) =>
                          setState(() => _verifiedOnly = value),
                    ),
                    FilterChip(
                      selected: _savedOnly,
                      label: Text(context.tr(bn: 'সেভ করা', en: 'Saved')),
                      avatar: const Icon(Icons.bookmark_rounded, size: 18),
                      onSelected: (value) => setState(() => _savedOnly = value),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clear,
                        child: Text(context.tr(bn: 'রিসেট', en: 'Reset')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _apply,
                        child: Text(
                          context.tr(bn: 'রেজাল্ট দেখুন', en: 'Show results'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorFilterTitle extends StatelessWidget {
  const _TutorFilterTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TutorPostComposerPage extends StatefulWidget {
  const _TutorPostComposerPage({required this.initialType});

  final _TutorPostType initialType;

  @override
  State<_TutorPostComposerPage> createState() => _TutorPostComposerPageState();
}

class _TutorPostComposerPageState extends State<_TutorPostComposerPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _levelController = TextEditingController();
  final _priceController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _remarksController = TextEditingController();

  late _TutorPostType _type = widget.initialType;
  final Set<String> _selectedSubjectEns = <String>{'All Subjects'};
  final _customSubjectController = TextEditingController();
  bool _isCustomSubjectEnabled = false;
  String _areaEn = _tutorAreas.first.labelEn;
  String _fulfillmentStatus = 'not_got';

  static const List<String> _quickLevels = [
    'ক্লাস ১-৫',
    'ক্লাস ৬-৮',
    '৯ম-১০ম (SSC)',
    'একাদশ-দ্বাদশ (HSC)',
    'মাদ্রাসা / হিফজ',
    'বিশ্ববিদ্যালয় ভর্তি',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _levelController.dispose();
    _priceController.dispose();
    _availabilityController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _descriptionController.dispose();
    _remarksController.dispose();
    _customSubjectController.dispose();
    super.dispose();
  }

  void _toggleSubject(_TutorSubjectData subject) {
    setState(() {
      final isCombo = subject.labelEn == 'All Subjects' ||
          subject.labelEn == 'Math & English' ||
          subject.labelEn == 'Bangla, English & Math' ||
          subject.labelEn == 'Science & Math';

      if (isCombo) {
        _selectedSubjectEns
          ..clear()
          ..add(subject.labelEn);
        return;
      }

      _selectedSubjectEns.remove('All Subjects');
      _selectedSubjectEns.remove('Math & English');
      _selectedSubjectEns.remove('Bangla, English & Math');
      _selectedSubjectEns.remove('Science & Math');

      if (_selectedSubjectEns.contains(subject.labelEn)) {
        _selectedSubjectEns.remove(subject.labelEn);
        if (_selectedSubjectEns.isEmpty && !_isCustomSubjectEnabled) {
          _selectedSubjectEns.add('All Subjects');
        }
      } else {
        _selectedSubjectEns.add(subject.labelEn);
      }
    });
  }

  String _formatSelectedSubjectBn() {
    final custom = _isCustomSubjectEnabled ? _customSubjectController.text.trim() : '';

    if (_selectedSubjectEns.contains('All Subjects')) {
      return custom.isEmpty ? 'সকল বিষয়' : 'সকল বিষয়, $custom';
    }
    if (_selectedSubjectEns.contains('Math & English')) {
      return custom.isEmpty ? 'গণিত ও ইংরেজি' : 'গণিত ও ইংরেজি, $custom';
    }
    if (_selectedSubjectEns.contains('Bangla, English & Math')) {
      return custom.isEmpty ? 'বাংলা, ইংরেজি ও গণিত' : 'বাংলা, ইংরেজি ও গণিত, $custom';
    }
    if (_selectedSubjectEns.contains('Science & Math')) {
      return custom.isEmpty ? 'বিজ্ঞান ও গণিত' : 'বিজ্ঞান ও গণিত, $custom';
    }

    final selected = _tutorSubjects
        .where((s) => _selectedSubjectEns.contains(s.labelEn))
        .map((s) => s.labelBn)
        .toList();
    if (custom.isNotEmpty) {
      selected.add(custom);
    }
    if (selected.isEmpty) {
      return 'সকল বিষয়';
    }
    return selected.join(', ');
  }

  String _formatSelectedSubjectEn() {
    final custom = _isCustomSubjectEnabled ? _customSubjectController.text.trim() : '';

    if (_selectedSubjectEns.contains('All Subjects')) {
      return custom.isEmpty ? 'All Subjects' : 'All Subjects, $custom';
    }
    if (_selectedSubjectEns.contains('Math & English')) {
      return custom.isEmpty ? 'Math & English' : 'Math & English, $custom';
    }
    if (_selectedSubjectEns.contains('Bangla, English & Math')) {
      return custom.isEmpty ? 'Bangla, English & Math' : 'Bangla, English & Math, $custom';
    }
    if (_selectedSubjectEns.contains('Science & Math')) {
      return custom.isEmpty ? 'Science & Math' : 'Science & Math, $custom';
    }

    final selected = _tutorSubjects
        .where((s) => _selectedSubjectEns.contains(s.labelEn))
        .map((s) => s.labelEn)
        .toList();
    if (custom.isNotEmpty) {
      selected.add(custom);
    }
    if (selected.isEmpty) {
      return 'All Subjects';
    }
    return selected.join(', ');
  }

  _TutorAreaOption get _selectedArea {
    return _tutorAreas.firstWhere(
      (area) => area.labelEn == _areaEn,
      orElse: () => _tutorAreas.first,
    );
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr(bn: 'এই তথ্যটি প্রয়োজন', en: 'This field is required');
    }

    return null;
  }

  String _priceBn(String amount) {
    final value = amount.trim();
    if (value.contains('৳') || value.contains('/')) {
      return value;
    }

    return '৳ $value / মাস';
  }

  String _priceEn(String amount) {
    final value = amount.trim();
    final lowerValue = value.toLowerCase();
    if (lowerValue.contains('tk') ||
        lowerValue.contains('৳') ||
        value.contains('/')) {
      return value;
    }

    return 'Tk $value / month';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final subjectBn = _formatSelectedSubjectBn();
    final subjectEn = _formatSelectedSubjectEn();
    final area = _selectedArea;
    final level = _levelController.text.trim();
    final fullSubjectBn = level.isEmpty
        ? subjectBn
        : '$subjectBn ($level)';
    final fullSubjectEn = level.isEmpty
        ? subjectEn
        : '$subjectEn ($level)';
    final description = _descriptionController.text.trim();
    final experience = _experienceController.text.trim();

    Navigator.of(context).pop(
      _TutorPostData(
        id: 'tutor-${DateTime.now().microsecondsSinceEpoch}',
        type: _type,
        name: _nameController.text.trim(),
        roleBn: _type.roleBn(),
        roleEn: _type.roleEn(),
        subjectBn: fullSubjectBn,
        subjectEn: fullSubjectEn,
        areaBn: area.labelBn,
        areaEn: area.labelEn,
        priceBn: _priceBn(_priceController.text),
        priceEn: _priceEn(_priceController.text),
        availabilityBn: _availabilityController.text.trim(),
        availabilityEn: _availabilityController.text.trim(),
        badgeBn: _type.badgeBn(),
        badgeEn: _type.badgeEn(),
        rating: _type == _TutorPostType.tutor ? 'New' : 'Open',
        phone: _phoneController.text.trim(),
        descriptionBn: description,
        descriptionEn: description,
        experienceBn: experience.isEmpty
            ? 'বিস্তারিত আলোচনার সময় জানানো হবে'
            : experience,
        experienceEn: experience.isEmpty
            ? 'Will be shared during discussion'
            : experience,
        fulfillmentStatus: _fulfillmentStatus,
        remarks: _remarksController.text.trim(),
        color: _type.color(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTutorPost = _type == _TutorPostType.tutor;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.tr(
            bn: isTutorPost ? 'শিক্ষক পোস্ট' : 'শিক্ষক চাই পোস্ট',
            en: isTutorPost ? 'Tutor Post' : 'Need Tutor Post',
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.publish_rounded),
            label: Text(context.tr(bn: 'পোস্ট প্রকাশ করুন', en: 'Publish')),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(bn: 'পোস্টের ধরন', en: 'Post type'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _TutorComposerTypeButton(
                          icon: Icons.school_rounded,
                          label: context.tr(bn: 'শিক্ষক দিচ্ছি', en: 'I teach'),
                          isSelected: _type == _TutorPostType.tutor,
                          color: const Color(0xFF0F766E),
                          onTap: () =>
                              setState(() => _type = _TutorPostType.tutor),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TutorComposerTypeButton(
                          icon: Icons.person_search_rounded,
                          label: context.tr(
                            bn: 'শিক্ষক নিচ্ছি',
                            en: 'Need tutor',
                          ),
                          isSelected: _type == _TutorPostType.request,
                          color: AppColors.accent,
                          onTap: () =>
                              setState(() => _type = _TutorPostType.request),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              validator: _requiredText,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.tr(
                  bn: isTutorPost ? 'আপনার নাম' : 'অভিভাবক/শিক্ষার্থীর নাম',
                  en: isTutorPost ? 'Your name' : 'Guardian/student name',
                ),
                prefixIcon: const Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 12),
            _buildSubjectSelectorSection(),
            const SizedBox(height: 14),
            TextFormField(
              controller: _levelController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.tr(bn: 'ক্লাস / লেভেল', en: 'Class / Level'),
                hintText: context.tr(
                  bn: 'যেমন: ক্লাস ১, ক্লাস ৫, এসএসসি ইত্যাদি',
                  en: 'e.g. Class 1, Class 5, SSC etc.',
                ),
                prefixIcon: const Icon(Icons.layers_rounded),
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickLevels
                    .map(
                      (level) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 14),
                          label: Text(level),
                          labelStyle: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          onPressed: () {
                            setState(() => _levelController.text = level);
                          },
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _areaEn,
              decoration: InputDecoration(
                labelText: context.tr(bn: 'এলাকা', en: 'Area'),
                prefixIcon: const Icon(Icons.place_rounded),
              ),
              items: _tutorAreas
                  .map(
                    (area) => DropdownMenuItem<String>(
                      value: area.labelEn,
                      child: Text(
                        context.tr(bn: area.labelBn, en: area.labelEn),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _areaEn = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              validator: _requiredText,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.tr(
                  bn: 'মাসিক ফি / বাজেট',
                  en: 'Fee / budget',
                ),
                prefixIcon: const Icon(Icons.payments_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _availabilityController,
              validator: _requiredText,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.tr(bn: 'সময়', en: 'Availability'),
                prefixIcon: const Icon(Icons.schedule_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              validator: _requiredText,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.tr(bn: 'মোবাইল নম্বর', en: 'Phone number'),
                prefixIcon: const Icon(Icons.call_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _experienceController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: context.tr(
                  bn: isTutorPost ? 'অভিজ্ঞতা' : 'শিক্ষকের যোগ্যতা',
                  en: isTutorPost ? 'Experience' : 'Tutor requirement',
                ),
                prefixIcon: const Icon(Icons.workspace_premium_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              validator: _requiredText,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: context.tr(bn: 'বিস্তারিত লিখুন', en: 'Details'),
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 72),
                  child: Icon(Icons.description_rounded),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(bn: 'পোস্টের ফলাফল', en: 'Post Result'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment<String>(
                        value: 'not_got',
                        icon: const Icon(Icons.hourglass_empty_rounded),
                        label: Text(
                          context.tr(bn: 'এখনও পায়নি', en: 'Not got yet'),
                        ),
                      ),
                      ButtonSegment<String>(
                        value: 'got',
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text(context.tr(bn: 'পেয়ে গেছে', en: 'Got')),
                      ),
                    ],
                    selected: {_fulfillmentStatus},
                    onSelectionChanged: (values) {
                      setState(() => _fulfillmentStatus = values.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _remarksController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: context.tr(bn: 'রিমার্কস', en: 'Remarks'),
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 48),
                        child: Icon(Icons.comment_rounded),
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

  Widget _buildSubjectSelectorSection() {
    final summaryBn = _formatSelectedSubjectBn();
    final summaryEn = _formatSelectedSubjectEn();
    final isAllSelected = _selectedSubjectEns.contains('All Subjects');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _selectedSubjectEns.isNotEmpty
              ? AppColors.primary.withValues(alpha: 0.3)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        bn: 'বিষয় নির্বাচন (একাধিক সিলেক্ট করুন)',
                        en: 'Select Subjects (Multi-select)',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      context.tr(
                        bn: 'অল সাবজেক্ট বা একাধিক বিষয় একসাথে বেছে নিন',
                        en: 'Pick All Subjects or multiple subjects together',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isAllSelected
                      ? context.tr(bn: 'অল সাবজেক্ট', en: 'All')
                      : '${_selectedSubjectEns.length} ${context.tr(bn: "টি বিষয়", en: "selected")}',
                  style: const TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Presets
          Text(
            context.tr(bn: 'জনপ্রিয় অপশন (১-ট্যাপ):', en: 'Popular Presets:'),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tutorSubjects.where((s) {
              return s.labelEn == 'All Subjects' ||
                  s.labelEn == 'Math & English' ||
                  s.labelEn == 'Bangla, English & Math' ||
                  s.labelEn == 'Science & Math';
            }).map((preset) {
              final isSelected = _selectedSubjectEns.contains(preset.labelEn);
              return FilterChip(
                selected: isSelected,
                avatar: Icon(
                  preset.icon,
                  size: 15,
                  color: isSelected ? Colors.white : preset.color,
                ),
                label: Text(
                  context.tr(bn: preset.labelBn, en: preset.labelEn),
                ),
                selectedColor: preset.color,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
                backgroundColor: const Color(0xFFF8FAFC),
                side: BorderSide(
                  color: isSelected ? preset.color : const Color(0xFFE2E8F0),
                ),
                onSelected: (_) => _toggleSubject(preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Specific Individual Subjects
          Text(
            context.tr(
              bn: 'নির্দিষ্ট বিষয় (প্রয়োজনমতো একাধিক সিলেক্ট করুন):',
              en: 'Specific Subjects (Select multiple as needed):',
            ),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _tutorSubjects.where((s) {
              return s.labelEn != 'All Subjects' &&
                  s.labelEn != 'Math & English' &&
                  s.labelEn != 'Bangla, English & Math' &&
                  s.labelEn != 'Science & Math';
            }).map((subject) {
              final isSelected = _selectedSubjectEns.contains(subject.labelEn);
              return FilterChip(
                selected: isSelected,
                avatar: Icon(
                  subject.icon,
                  size: 14,
                  color: isSelected ? Colors.white : subject.color,
                ),
                label: Text(
                  context.tr(bn: subject.labelBn, en: subject.labelEn),
                ),
                selectedColor: subject.color,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11.5,
                ),
                backgroundColor: const Color(0xFFF8FAFC),
                side: BorderSide(
                  color: isSelected ? subject.color : const Color(0xFFCBD5E1),
                ),
                onSelected: (_) => _toggleSubject(subject),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Custom Subject Input Toggle
          Row(
            children: [
              Checkbox(
                value: _isCustomSubjectEnabled,
                visualDensity: VisualDensity.compact,
                onChanged: (val) {
                  setState(() => _isCustomSubjectEnabled = val ?? false);
                },
              ),
              GestureDetector(
                onTap: () {
                  setState(() => _isCustomSubjectEnabled = !_isCustomSubjectEnabled);
                },
                child: Text(
                  context.tr(
                    bn: 'অন্যান্য বিষয় যোগ করুন (Custom Subject)',
                    en: 'Add Other Custom Subject',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          if (_isCustomSubjectEnabled) ...[
            const SizedBox(height: 4),
            TextFormField(
              controller: _customSubjectController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: context.tr(
                  bn: 'যেমন: ড্রয়িং, আরবি, সঙ্গীত ইত্যাদি',
                  en: 'e.g. Drawing, Arabic, Music etc.',
                ),
                prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Selected Summary Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${context.tr(bn: "নির্বাচিত বিষয়:", en: "Selected:")} ${context.tr(bn: summaryBn, en: summaryEn)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorComposerTypeButton extends StatelessWidget {
  const _TutorComposerTypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.3 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected ? color : AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorPostDetailsPage extends StatefulWidget {
  const _TutorPostDetailsPage({
    required this.post,
    required this.isSaved,
    required this.onToggleSaved,
  });

  final _TutorPostData post;
  final bool isSaved;
  final VoidCallback onToggleSaved;

  @override
  State<_TutorPostDetailsPage> createState() => _TutorPostDetailsPageState();
}

class _TutorPostDetailsPageState extends State<_TutorPostDetailsPage> {
  late bool _isSaved = widget.isSaved;

  void _toggleSaved() {
    setState(() => _isSaved = !_isSaved);
    widget.onToggleSaved();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSaved
              ? context.tr(bn: 'পোস্টটি সেভ করা হয়েছে।', en: 'Post saved.')
              : context.tr(
                  bn: 'সেভ করা পোস্ট থেকে সরানো হয়েছে।',
                  en: 'Removed from saved posts.',
                ),
        ),
      ),
    );
  }

  Future<void> _openMessageChat() async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TutorMessageSheet(post: widget.post),
    );

    if (message == null || message.trim().isEmpty || !mounted) {
      return;
    }

    await _launchContactUri(
      Uri(
        scheme: 'sms',
        path: _normalizedPhoneNumber(),
        queryParameters: <String, String>{'body': message.trim()},
      ),
      failureMessage: context.tr(
        bn: 'মেসেজ অ্যাপ খোলা যাচ্ছে না।',
        en: 'Could not open the message app.',
      ),
    );
  }

  Future<void> _openAudioCall() async {
    await _launchContactUri(
      Uri(scheme: 'tel', path: _normalizedPhoneNumber()),
      failureMessage: context.tr(
        bn: 'ফোন ডায়ালার খোলা যাচ্ছে না।',
        en: 'Could not open the phone dialer.',
      ),
    );
  }

  String _normalizedPhoneNumber() {
    return widget.post.phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  Future<void> _launchContactUri(
    Uri uri, {
    required String failureMessage,
  }) async {
    final phone = _normalizedPhoneNumber();
    if (phone.isEmpty) {
      _showStatus(
        context.tr(
          bn: 'এই পোস্টে ফোন নম্বর পাওয়া যায়নি।',
          en: 'No phone number was found for this post.',
        ),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) {
      return;
    }
    if (!launched) {
      _showStatus(failureMessage);
    }
  }

  void _showStatus(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return _DetailScaffold(
      title: post.type == _TutorPostType.tutor ? 'Tutor Profile' : 'Need Tutor',
      trailing: IconButton(
        onPressed: _toggleSaved,
        icon: Icon(
          _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          color: _isSaved ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      bottomAction: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _openAudioCall,
              icon: const Icon(Icons.call_rounded),
              label: Text(context.tr(bn: 'অডিও কল', en: 'Audio Call')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _openMessageChat,
              icon: const Icon(Icons.chat_bubble_rounded),
              label: Text(context.tr(bn: 'মেসেজ', en: 'Message')),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassPanel(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: post.color.withValues(alpha: 0.13),
                      child: Text(
                        post.name.characters.first,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: post.color,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  post.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              if (post.verified)
                                const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(bn: post.roleBn, en: post.roleEn),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _TutorStatusBadge(
                                label: context.tr(
                                  bn: post.badgeBn,
                                  en: post.badgeEn,
                                ),
                                color: post.color,
                              ),
                              _TutorStatusBadge(
                                label: post.rating,
                                color: AppColors.warning,
                              ),
                              _TutorStatusBadge(
                                label: context.tr(
                                  bn: post.fulfillmentLabelBn(),
                                  en: post.fulfillmentLabelEn(),
                                ),
                                color: post.fulfillmentColor(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _TutorDetailGrid(post: post),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(bn: 'বিস্তারিত', en: 'Details'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(bn: post.descriptionBn, en: post.descriptionEn),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (post.remarks.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _TutorInfoLine(
                    icon: Icons.comment_rounded,
                    label: post.remarks,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassPanel(
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(
                      bn: 'ব্যক্তিগত তথ্য যাচাই করে যোগাযোগ করুন। পেমেন্ট বা অগ্রিম দেওয়ার আগে অভিভাবক/শিক্ষকের সাথে সরাসরি কথা বলুন।',
                      en: 'Verify details before contacting. Discuss directly before any payment or advance.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorDetailGrid extends StatelessWidget {
  const _TutorDetailGrid({required this.post});

  final _TutorPostData post;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TutorInfoLine(
                icon: Icons.menu_book_rounded,
                label: context.tr(bn: post.subjectBn, en: post.subjectEn),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TutorInfoLine(
                icon: Icons.place_rounded,
                label: context.tr(bn: post.areaBn, en: post.areaEn),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TutorInfoLine(
                icon: Icons.payments_rounded,
                label: context.tr(bn: post.priceBn, en: post.priceEn),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TutorInfoLine(
                icon: Icons.schedule_rounded,
                label: context.tr(
                  bn: post.availabilityBn,
                  en: post.availabilityEn,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _TutorInfoLine(
          icon: Icons.workspace_premium_rounded,
          label: context.tr(bn: post.experienceBn, en: post.experienceEn),
        ),
      ],
    );
  }
}

class _TutorMessageSheet extends StatefulWidget {
  const _TutorMessageSheet({required this.post});

  final _TutorPostData post;

  @override
  State<_TutorMessageSheet> createState() => _TutorMessageSheetState();
}

class _TutorMessageSheetState extends State<_TutorMessageSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messageController.text = widget.post.type == _TutorPostType.tutor
        ? 'I am interested in your tuition service.'
        : 'I am available for this tuition request.';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return context.tr(bn: 'মেসেজ লিখুন', en: 'Write a message');
    }

    return null;
  }

  void _send() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(_messageController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.card,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(bn: 'মেসেজ পাঠান', en: 'Send message'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.post.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  validator: _requiredText,
                  minLines: 4,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: context.tr(
                      bn: 'আপনার মেসেজ',
                      en: 'Your message',
                    ),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded),
                  label: Text(context.tr(bn: 'পাঠান', en: 'Send')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _TutorPostType { tutor, request }

extension _TutorPostTypeLabel on _TutorPostType {
  String badgeBn() {
    return switch (this) {
      _TutorPostType.tutor => 'শিক্ষক',
      _TutorPostType.request => 'শিক্ষক চাই',
    };
  }

  String badgeEn() {
    return switch (this) {
      _TutorPostType.tutor => 'Tutor',
      _TutorPostType.request => 'Need Tutor',
    };
  }

  String roleBn() {
    return switch (this) {
      _TutorPostType.tutor => 'শিক্ষক পোস্ট',
      _TutorPostType.request => 'অভিভাবক/শিক্ষার্থী পোস্ট',
    };
  }

  String roleEn() {
    return switch (this) {
      _TutorPostType.tutor => 'Tutor post',
      _TutorPostType.request => 'Guardian/student request',
    };
  }

  String apiValue() {
    return switch (this) {
      _TutorPostType.tutor => 'tutor',
      _TutorPostType.request => 'request',
    };
  }

  Color color() {
    return switch (this) {
      _TutorPostType.tutor => const Color(0xFF0F766E),
      _TutorPostType.request => AppColors.accent,
    };
  }
}

_TutorPostType _tutorPostTypeFromApiValue(String value) {
  return switch (value.trim().toLowerCase()) {
    'request' ||
    'need_tutor' ||
    'need-tutor' ||
    'student' ||
    'guardian' => _TutorPostType.request,
    _ => _TutorPostType.tutor,
  };
}

class _TutorIntentOption {
  const _TutorIntentOption({
    required this.type,
    required this.titleBn,
    required this.titleEn,
    required this.subtitleBn,
    required this.subtitleEn,
    required this.icon,
    required this.color,
  });

  final _TutorPostType type;
  final String titleBn;
  final String titleEn;
  final String subtitleBn;
  final String subtitleEn;
  final IconData icon;
  final Color color;
}

class _TutorSubjectData {
  const _TutorSubjectData({
    required this.labelBn,
    required this.labelEn,
    required this.icon,
    required this.color,
  });

  final String labelBn;
  final String labelEn;
  final IconData icon;
  final Color color;
}

class _TutorAreaOption {
  const _TutorAreaOption({required this.labelBn, required this.labelEn});

  final String labelBn;
  final String labelEn;
}

class _TutorPostData {
  const _TutorPostData({
    required this.id,
    required this.type,
    required this.name,
    required this.roleBn,
    required this.roleEn,
    required this.subjectBn,
    required this.subjectEn,
    required this.areaBn,
    required this.areaEn,
    required this.priceBn,
    required this.priceEn,
    required this.availabilityBn,
    required this.availabilityEn,
    required this.badgeBn,
    required this.badgeEn,
    required this.rating,
    required this.phone,
    required this.descriptionBn,
    required this.descriptionEn,
    required this.experienceBn,
    required this.experienceEn,
    required this.fulfillmentStatus,
    required this.remarks,
    required this.color,
    this.verified = false,
  });

  final String id;
  final _TutorPostType type;
  final String name;
  final String roleBn;
  final String roleEn;
  final String subjectBn;
  final String subjectEn;
  final String areaBn;
  final String areaEn;
  final String priceBn;
  final String priceEn;
  final String availabilityBn;
  final String availabilityEn;
  final String badgeBn;
  final String badgeEn;
  final String rating;
  final String phone;
  final String descriptionBn;
  final String descriptionEn;
  final String experienceBn;
  final String experienceEn;
  final String fulfillmentStatus;
  final String remarks;
  final Color color;
  final bool verified;

  bool get isFulfilled => fulfillmentStatus.trim().toLowerCase() == 'got';

  String fulfillmentLabelBn() {
    return isFulfilled ? 'পেয়ে গেছে' : 'এখনও পায়নি';
  }

  String fulfillmentLabelEn() {
    return isFulfilled ? 'Got' : 'Not got yet';
  }

  Color fulfillmentColor() {
    return isFulfilled ? AppColors.success : AppColors.warning;
  }

  factory _TutorPostData.fromApi(TenantTutorPost post) {
    final type = _tutorPostTypeFromApiValue(post.type);

    return _TutorPostData(
      id: post.id.isEmpty
          ? 'tutor-${DateTime.now().microsecondsSinceEpoch}'
          : post.id,
      type: type,
      name: post.name,
      roleBn: post.role.bn,
      roleEn: post.role.en,
      subjectBn: post.subject.bn,
      subjectEn: post.subject.en,
      areaBn: post.area.bn,
      areaEn: post.area.en,
      priceBn: post.price.bn,
      priceEn: post.price.en,
      availabilityBn: post.availability.bn,
      availabilityEn: post.availability.en,
      badgeBn: post.badge.bn,
      badgeEn: post.badge.en,
      rating: post.rating,
      phone: post.phone,
      descriptionBn: post.description.bn,
      descriptionEn: post.description.en,
      experienceBn: post.experience.bn,
      experienceEn: post.experience.en,
      fulfillmentStatus: post.fulfillmentStatus,
      remarks: post.remarks,
      color: type.color(),
      verified: post.verified,
    );
  }

  TenantTutorCreatePostInput toCreatePostInput() {
    return TenantTutorCreatePostInput(
      type: type.apiValue(),
      name: name,
      roleBn: roleBn,
      roleEn: roleEn,
      subjectBn: subjectBn,
      subjectEn: subjectEn,
      areaBn: areaBn,
      areaEn: areaEn,
      priceBn: priceBn,
      priceEn: priceEn,
      availabilityBn: availabilityBn,
      availabilityEn: availabilityEn,
      phone: phone,
      descriptionBn: descriptionBn,
      descriptionEn: descriptionEn,
      experienceBn: experienceBn,
      experienceEn: experienceEn,
      fulfillmentStatus: fulfillmentStatus,
      remarks: remarks,
    );
  }
}

const _tutorIntentOptions = <_TutorIntentOption>[
  _TutorIntentOption(
    type: _TutorPostType.tutor,
    titleBn: 'শিক্ষক দিচ্ছি',
    titleEn: 'I Teach',
    subtitleBn: 'আপনার টিউশন সার্ভিস পোস্ট করুন',
    subtitleEn: 'Post your tuition service',
    icon: Icons.school_rounded,
    color: Color(0xFF0F766E),
  ),
  _TutorIntentOption(
    type: _TutorPostType.request,
    titleBn: 'শিক্ষক নিচ্ছি',
    titleEn: 'I Need Tutor',
    subtitleBn: 'ক্লাস, বিষয় ও সময় দিয়ে অনুরোধ করুন',
    subtitleEn: 'Request by class, subject, and time',
    icon: Icons.person_search_rounded,
    color: Color(0xFFF97316),
  ),
];

const _tutorSubjects = <_TutorSubjectData>[
  _TutorSubjectData(
    labelBn: 'সকল বিষয়',
    labelEn: 'All Subjects',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF2563EB),
  ),
  _TutorSubjectData(
    labelBn: 'বাংলা',
    labelEn: 'Bangla',
    icon: Icons.translate_rounded,
    color: Color(0xFFE11D48),
  ),
  _TutorSubjectData(
    labelBn: 'ইংরেজি',
    labelEn: 'English',
    icon: Icons.language_rounded,
    color: Color(0xFF7C3AED),
  ),
  _TutorSubjectData(
    labelBn: 'গণিত',
    labelEn: 'Math',
    icon: Icons.calculate_rounded,
    color: AppColors.primary,
  ),
  _TutorSubjectData(
    labelBn: 'গণিত ও ইংরেজি',
    labelEn: 'Math & English',
    icon: Icons.auto_stories_rounded,
    color: Color(0xFF0284C7),
  ),
  _TutorSubjectData(
    labelBn: 'বাংলা, ইংরেজি ও গণিত',
    labelEn: 'Bangla, English & Math',
    icon: Icons.school_rounded,
    color: Color(0xFF4F46E5),
  ),
  _TutorSubjectData(
    labelBn: 'বিজ্ঞান',
    labelEn: 'Science',
    icon: Icons.science_rounded,
    color: AppColors.success,
  ),
  _TutorSubjectData(
    labelBn: 'বিজ্ঞান ও গণিত',
    labelEn: 'Science & Math',
    icon: Icons.biotech_rounded,
    color: Color(0xFF059669),
  ),
  _TutorSubjectData(
    labelBn: 'আইসিটি',
    labelEn: 'ICT',
    icon: Icons.computer_rounded,
    color: Color(0xFF0891B2),
  ),
  _TutorSubjectData(
    labelBn: 'কোরআন',
    labelEn: 'Quran',
    icon: Icons.auto_stories_rounded,
    color: AppColors.accent,
  ),
  _TutorSubjectData(
    labelBn: 'পদার্থবিজ্ঞান',
    labelEn: 'Physics',
    icon: Icons.bolt_rounded,
    color: Color(0xFF9333EA),
  ),
  _TutorSubjectData(
    labelBn: 'রসায়ন',
    labelEn: 'Chemistry',
    icon: Icons.bubble_chart_rounded,
    color: Color(0xFF10B981),
  ),
  _TutorSubjectData(
    labelBn: 'জীববিজ্ঞান',
    labelEn: 'Biology',
    icon: Icons.eco_rounded,
    color: Color(0xFF16A34A),
  ),
  _TutorSubjectData(
    labelBn: 'উচ্চতর গণিত',
    labelEn: 'Higher Math',
    icon: Icons.functions_rounded,
    color: Color(0xFFD97706),
  ),
  _TutorSubjectData(
    labelBn: 'হিসাববিজ্ঞান',
    labelEn: 'Accounting',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFFEA580C),
  ),
  _TutorSubjectData(
    labelBn: 'সাধারণ জ্ঞান',
    labelEn: 'General Knowledge',
    icon: Icons.public_rounded,
    color: Color(0xFF0D9488),
  ),
];

const _tutorAreas = <_TutorAreaOption>[
  _TutorAreaOption(labelBn: 'মিরপুর ১০', labelEn: 'Mirpur 10'),
  _TutorAreaOption(labelBn: 'উত্তরা সেক্টর ৭', labelEn: 'Uttara Sector 7'),
  _TutorAreaOption(labelBn: 'ধানমন্ডি ২৭', labelEn: 'Dhanmondi 27'),
  _TutorAreaOption(labelBn: 'মোহাম্মদপুর', labelEn: 'Mohammadpur'),
  _TutorAreaOption(labelBn: 'গুলশান ২', labelEn: 'Gulshan 2'),
];
