import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../services/accessibility_theme.dart';
import '../services/auth_service.dart';
import '../services/favorites_store.dart';
import '../widgets/favorite_toggle_button.dart';
import '../widgets/search_suggestion_list.dart';

const Map<String, IconData> _iconOptions = {
  'book': Icons.auto_stories,
  'school': Icons.school_outlined,
  'award': Icons.emoji_events_outlined,
  'career': Icons.work_outline,
  'public': Icons.public_outlined,
  'star': Icons.star_outline,
};

class OpportunitiesScreen extends StatefulWidget {
  final http.Client? client;
  final String? initialOpportunityId;

  const OpportunitiesScreen({
    super.key,
    this.client,
    this.initialOpportunityId,
  });

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  static const Duration _requestTimeout = Duration(seconds: 10);

  bool _isLoading = true;
  List<_ScholarshipResource> _resources = List.of(_defaultResources);
  String? _selectedCategory;
  bool _includeExpired = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final http.Client _client;
  late final bool _ownsClient;

  static const List<_ScholarshipResource> _defaultResources = [
    _ScholarshipResource(
      title: 'SOMOS Scholarships',
      category: 'SOMOS',
      description:
          'List of scholarships and opportunities for SOMOS, Ummah, and Ubuntu students.',
      iconKey: 'book',
      links: [
        _ScholarshipLink(
          name: 'Spirit of Giving',
          url:
              'https://www.winecountrygiftbaskets.com/information/scholarship.asp?srsltid=AfmBOorZirDGNmjoTYp0012FuEBOmL4sSxC54JfpgxXuKkD4UILa99Z9',
        ),
        _ScholarshipLink(
          name: 'Hope College Scholarship',
          url:
              'https://scholarships.sofiashope.org/?gad_source=1&gad_campaignid=22767042193&gbraid=0AAAAABJPZR5h7skRdflBR815h6GqSr5H3&gclid=Cj0KCQjwkILEBhDeARIsAL--pjzKdKWccMkaVu1HWZDRb4TKWMR4gNU3R0YXwwMBrmxCNCND_QyMenUaAqewEALw_wcB',
        ),
        _ScholarshipLink(
          name: 'Nueva Generacion',
          url:
              'https://californiafarmworkers.org/what-we-do/nueva-generacion-scholarship-program/',
        ),
        _ScholarshipLink(
          name: 'Chicana Latina',
          url: 'https://chicanalatina.org/programs/scholarships/',
        ),
        _ScholarshipLink(
          name: 'A Better Financial',
          url:
              'https://www.afsusa.org/study-abroad/scholarships/?lead_source=mediacause&utm_source=google-grant&utm_medium=ad-grant&utm_campaign=scholarships&utm_content=general-scholarships&creative=685517597456&keyword=scholarship%20programs%20for%20high%20school&matchtype=b&network=g&device=c&gad_source=1&gad_campaignid=1997297492&gbraid=0AAAAADs0D_8MlXNKek0Qi4I2Wxq7i2bWu&gclid=Cj0KCQjwkILEBhDeARIsAL--pjzNab0jxarQa08KhoWTtkG2ymX5gr-wuKPMv3aluBhqkx29yWtnUeQaAmnMEALw_wcB',
        ),
        //AICP Scholarship program link not working
        _ScholarshipLink(name: 'AICP Scholarship program', url: ''),
        //Double A Solution Scholarship link not working
        _ScholarshipLink(name: 'Double A Solution Scholarship', url: ''),
        _ScholarshipLink(
          name: 'Dreamer\'s Roadmap Scholarship',
          url:
              'https://www.afsusa.org/study-abroad/scholarships/?lead_source=mediacause&utm_source=google-grant&utm_medium=ad-grant&utm_campaign=scholarships&utm_content=general-scholarships&creative=685517597456&keyword=scholarship%20programs%20for%20high%20school&matchtype=b&network=g&device=c&gad_source=1&gad_campaignid=1997297492&gbraid=0AAAAADs0D_8MlXNKek0Qi4I2Wxq7i2bWu&gclid=Cj0KCQjwkILEBhDeARIsAL--pjzNab0jxarQa08KhoWTtkG2ymX5gr-wuKPMv3aluBhqkx29yWtnUeQaAmnMEALw_wcB',
        ),
        _ScholarshipLink(
          name: 'El Futuro Scholarship',
          url: 'https://sachcc.org/scholarship/',
        ),
        _ScholarshipLink(
          name: 'Cien Amigos IME Becas',
          url: 'https://cienamigosedfund.org/',
        ),
        _ScholarshipLink(
          name: 'BigSum Scholarship',
          url: 'https://bigsunathletics.com/',
        ),
        _ScholarshipLink(
          name: 'Omega Phi Beta Foundation',
          url: 'http://opbfoundation.org/scholarships/',
        ),
        _ScholarshipLink(
          name: 'Philip R. Nathe Scholarship',
          url: 'https://www.napervilledui.com/',
        ),
        _ScholarshipLink(
          name: 'RealityHop Scholarship',
          url:
              'https://www.ebcf.org/grants/scholarship-opportunities/?gad_source=1&gad_campaignid=20717852309&gbraid=0AAAAAo7ul86mzguYQHCn-pfdATO-KqZzJ&gclid=Cj0KCQjwkILEBhDeARIsAL--pjzfsfTzHC3VeH2aYDecNHThV5HRMWuPLfv9U5KFJF9ir6hnXrmrlCkaAt7mEALw_wcB',
        ),
        _ScholarshipLink(
          name: 'A. Martin Latino Scholarship',
          url:
              'https://www.financialaidfinder.com/antonia-martin-latino-educators-scholarship/',
        ),
      ],
    ),
    _ScholarshipResource(
      title: 'Ummah Scholarships',
      category: 'Ummah',
      description: 'List of scholarships and opportunities for Ummah students.',
      iconKey: 'book',
      links: [
        _ScholarshipLink(
          name: 'MYLA Education Scholarship',
          url: 'https://www.mylawards.org/',
        ),
        _ScholarshipLink(
          name: 'ISNA Scholarships',
          url: 'https://isna.net/scholarships',
        ),
        _ScholarshipLink(
          name: 'SAJA Scholarships',
          url: 'https://www.saja.org/scholarships',
        ),
        _ScholarshipLink(
          name: 'CAAP Scholarships',
          url: 'https://www.centeraap.org/grants/scholarships/',
        ),
        _ScholarshipLink(
          name: 'Abdelkader Leadership Prize',
          url: 'https://abdelkaderproject.org/',
        ),
        _ScholarshipLink(
          name: 'Barakat Senior Scholar',
          url: 'https://barakat.org/grants/#grants-overview',
        ),
        _ScholarshipLink(
          name: 'Islamic Scholarship Fund',
          url:
              'https://www.islamicscholarshipfund.org/create-your-own-scholarship',
        ),
        _ScholarshipLink(
          name: 'Muslim Women Scholarship',
          url: 'https://www.scholarshipsforwomen.net/muslim/',
        ),
        _ScholarshipLink(
          name: 'SALAM\'s Education Scholarship',
          url: 'https://salamcenter.org/education-scholarships/',
        ),
        _ScholarshipLink(
          name: 'Manera West Scholarship',
          url: 'https://manarawest.org/resources/',
        ),
        _ScholarshipLink(
          name: 'Amana Mutual Funds Scholarship',
          url:
              'https://bigfuture.collegeboard.org/scholarships/amana-mutual-funds-scholarship',
        ),
        _ScholarshipLink(
          name: 'The Islamic Seminary of America',
          url: 'https://islamicseminary.us/scholarships/',
        ),
        _ScholarshipLink(
          name: 'SMUD Powering Futures',
          url: 'https://www.smud.org/In-Our-Community/College-Scholarships',
        ),
        _ScholarshipLink(
          name: 'Sac Region Community Foundation',
          url: 'https://sacregcf.academicworks.com/opportunities',
        ),
        _ScholarshipLink(
          name: 'MAX Scholarship Fund',
          url: 'https://maxscholars.org/scholarships',
        ),
      ],
    ),
    _ScholarshipResource(
      title: 'Ubuntu Scholarships',
      category: 'Ubuntu',
      description:
          'List of scholarships and opportunities for Ubuntu students.',
      iconKey: 'book',
      links: [
        _ScholarshipLink(
          name: 'Alpha Phi Alpha Fraternity',
          url: 'https://www.sacalphas.org/scholarship',
        ),
        _ScholarshipLink(
          name: 'Sac Region Community Foundation',
          url: 'https://sacregcf.academicworks.com/opportunities',
        ),
        _ScholarshipLink(
          name: 'SMUD Powering Futures',
          url: 'https://www.smud.org/In-Our-Community/College-Scholarships',
        ),
        _ScholarshipLink(
          name: 'AMA Foundation Scholarship',
          url: 'https://amafoundation.org/',
        ),
        _ScholarshipLink(
          name: 'Black Nurses Association',
          url: 'https://ccbna.org/scholarships/',
        ),
        _ScholarshipLink(
          name: 'Ancestry History Makers',
          url: 'https://learnmore.scholarsapply.org/ancestry/',
        ),
        _ScholarshipLink(
          name: 'Harry S. Truman Foundation',
          url: 'https://www.truman.gov/apply',
        ),
        _ScholarshipLink(
          name: 'School House Connection',
          url:
              'https://schoolhouseconnection.org/article/5-guides-to-help-homeless-college-students-in-california',
        ),
        _ScholarshipLink(
          name: 'Marshall Scholarship',
          url: 'https://www.marshallscholarship.org/',
        ),
        _ScholarshipLink(
          name: 'CA Homebuilding Foundation',
          url: 'https://www.mychf.org/college-scholarships',
        ),
        _ScholarshipLink(
          name: 'ACS Scholarship in Chemistry',
          url:
              'https://www.acs.org/education/acs-undergraduate-scholarship.html',
        ),
        _ScholarshipLink(
          name: 'CalKIDS Scholarship',
          url: 'https://calkids.org/',
        ),
        _ScholarshipLink(
          name: 'Congressional Black Caucus',
          url: 'https://www.cbcfinc.org/programs/scholarships/',
        ),
        _ScholarshipLink(
          name: 'Square Root Academy',
          url: 'https://www.squarerootacademy.com/',
        ),
        _ScholarshipLink(
          name: 'CIEF Scholarship in Architecture',
          url: 'https://www.cie.foundation/scholarships.html',
        ),
        _ScholarshipLink(
          name: 'Frederick Roberts Scholarship',
          url: 'https://cablackcaucus.org/scholarships/',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? http.Client();
    _ownsClient = widget.client == null;
    _loadResources();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsClient) _client.close();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
    });
  }

  Future<void> _loadResources() async {
    final uri = _apiUri('/api/opportunities');
    if (uri == null) {
      _finishLoadingWithError('API_BASE_URL is missing from .env.');
      return;
    }

    try {
      final response = await _client.get(uri).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw StateError('GET returned ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data is! List) throw const FormatException('Expected a list');

      if (!mounted) return;
      setState(() {
        _resources = data
            .map(
              (item) =>
                  _ScholarshipResource.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        _isLoading = false;
      });
      _openInitialFavoriteIfRequested();
    } catch (_) {
      _finishLoadingWithError(
        'Could not load opportunities. Please try again.',
      );
    }
  }

  Uri? _apiUri(String path) {
    final baseUrl = AuthService.baseUrl;
    if (baseUrl == null) return null;
    return Uri.parse('$baseUrl$path');
  }

  void _finishLoadingWithError(String message) {
    if (!mounted) return;
    setState(() {
      _resources = [];
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        if (widget.initialOpportunityId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This saved opportunity is no longer available.'),
            ),
          );
        }
      }
    });
  }

  void _openInitialFavoriteIfRequested() {
    final id = widget.initialOpportunityId;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final matches = _resources.where(
        (resource) => resource.favoriteId == id,
      );
      if (matches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This saved opportunity is no longer available.'),
          ),
        );
        return;
      }
      _showResourceInformation(context, matches.first);
    });
  }

  void _showRequestError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openLink(BuildContext context, String url) async {
    if (url.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No link provided')));
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid URL format')));
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  void _showResourceInformation(
    BuildContext context,
    _ScholarshipResource resource,
  ) {
    final visibleLinks = resource.visibleLinks(
      DateUtils.dateOnly(DateTime.now()),
      AuthService.isAdmin && _includeExpired,
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _ResourceInfoDialog(
        resource: resource,
        links: visibleLinks,
        onOpenLink: _openLink,
      ),
    );
  }

  Future<void> _showOpportunityDialog({int? index}) async {
    final isEditing = index != null;
    final target = isEditing ? _resources[index] : null;

    final result = await showDialog<_ScholarshipResource>(
      context: context,
      builder: (dialogContext) =>
          _OpportunityEditorDialog(initialResource: target),
    );

    if (result == null) return;

    final uri = _apiUri(
      isEditing ? '/api/opportunities/${result.id}' : '/api/opportunities',
    );
    if (uri == null) {
      _showRequestError('API_BASE_URL is missing from .env.');
      return;
    }

    try {
      final body = jsonEncode(result.toJson());
      final response = isEditing
          ? await _client
                .put(
                  uri,
                  headers: {'Content-Type': 'application/json'},
                  body: body,
                )
                .timeout(_requestTimeout)
          : await _client
                .post(
                  uri,
                  headers: {'Content-Type': 'application/json'},
                  body: body,
                )
                .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw StateError(
          '${isEditing ? 'PUT' : 'POST'} returned ${response.statusCode}',
        );
      }

      final saved = _ScholarshipResource.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      if (!mounted) return;
      setState(() {
        if (isEditing) {
          _resources[index] = saved;
        } else {
          _resources.add(saved);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Opportunity updated' : 'Opportunity added',
          ),
        ),
      );
    } catch (_) {
      _showRequestError(
        isEditing
            ? 'Could not update the opportunity. Please try again.'
            : 'Could not add the opportunity. Please try again.',
      );
    }
  }

  Future<void> _deleteResource(int index) async {
    final colors = AccessibilityColors.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Opportunity'),
        content: const Text(
          'Are you sure you want to delete this opportunity?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.destructive,
              foregroundColor: colors.onPrimary,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final id = _resources[index].id;
    final uri = id == null ? null : _apiUri('/api/opportunities/$id');
    if (uri == null) {
      _showRequestError('Could not delete the opportunity. Please try again.');
      return;
    }

    try {
      final response = await _client.delete(uri).timeout(_requestTimeout);
      if (response.statusCode != 200) {
        throw StateError('DELETE returned ${response.statusCode}');
      }

      if (!mounted) return;
      setState(() => _resources.removeAt(index));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Opportunity deleted')));
    } catch (_) {
      _showRequestError('Could not delete the opportunity. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);
    final isAdmin = AuthService.isAdmin;

    final categories = _resources
        .map((r) => r.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();
    // Fall back to "All" if the selected category no longer exists.
    final selected = categories.contains(_selectedCategory)
        ? _selectedCategory
        : null;
    final today = DateUtils.dateOnly(DateTime.now());
    final includeExpired = isAdmin && _includeExpired;
    // Keep original indexes so edit/delete target the right resource.
    final visibleIndexes = [
      for (var i = 0; i < _resources.length; i++)
        if ((selected == null || _resources[i].category == selected) &&
            _resources[i].matchesKeyword(_searchQuery) &&
            _resources[i].hasVisibleLinks(today, includeExpired))
          i,
    ];
    visibleIndexes.sort(
      (left, right) => _resources[left].compareDisplayedOrder(
        _resources[right],
        today,
        includeExpired,
      ),
    );
    final resultLabel = visibleIndexes.length == 1
        ? '1 opportunity found'
        : '${visibleIndexes.length} opportunities found';
    final suggestions = _searchQuery.trim().isEmpty
        ? const <SearchSuggestion>[]
        : visibleIndexes
              .take(5)
              .map((index) {
                final resource = _resources[index];
                return SearchSuggestion(
                  title: resource.title,
                  subtitle: resource.category.isEmpty
                      ? null
                      : resource.category,
                  onSelected: () => _showResourceInformation(context, resource),
                );
              })
              .toList(growable: false);
    final hasActiveFilters = selected != null || _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: colors.pageBackground,
      appBar: AppBar(
        title: const Text(
          'Opportunities',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        centerTitle: true,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Add opportunity',
              onPressed: () => _showOpportunityDialog(),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'Search opportunities',
                          hintText: 'Search programs or organizations',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.trim().isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Clear opportunity search',
                                  onPressed: _clearSearch,
                                ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      SearchSuggestionList(suggestions: suggestions),
                    ],
                  ),
                ),
                if (categories.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        for (final category in [null, ...categories])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category ?? 'All'),
                              selected: selected == category,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = category),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (isAdmin)
                  SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    title: const Text('Include expired opportunities'),
                    value: _includeExpired,
                    onChanged: (value) =>
                        setState(() => _includeExpired = value),
                  ),
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(resultLabel),
                    ),
                  ),
                ),
                if (visibleIndexes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'No opportunities found.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try another keyword or clear your filters.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (hasActiveFilters)
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear filters'),
                          ),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (var i = 0; i < visibleIndexes.length; i++) ...[
                          _ResourceCard(
                            resource: _resources[visibleIndexes[i]],
                            isAdmin: isAdmin,
                            deadline: _resources[visibleIndexes[i]]
                                .nextVisibleDeadline(today, includeExpired),
                            onTap: () => _showResourceInformation(
                              context,
                              _resources[visibleIndexes[i]],
                            ),
                            onDelete: () => _deleteResource(visibleIndexes[i]),
                            onEdit: () => _showOpportunityDialog(
                              index: visibleIndexes[i],
                            ),
                          ),
                          if (i < visibleIndexes.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ResourceInfoDialog extends StatefulWidget {
  final _ScholarshipResource resource;
  final List<_ScholarshipLink> links;
  final Function(BuildContext, String) onOpenLink;

  const _ResourceInfoDialog({
    required this.resource,
    required this.links,
    required this.onOpenLink,
  });

  @override
  State<_ResourceInfoDialog> createState() => _ResourceInfoDialogState();
}

class _ResourceInfoDialogState extends State<_ResourceInfoDialog> {
  final descriptionScrollController = ScrollController();
  final linksScrollController = ScrollController();

  @override
  void dispose() {
    descriptionScrollController.dispose();
    linksScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final colors = AccessibilityColors.of(context);

    return Dialog(
      backgroundColor: colors.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.92,
          maxHeight: screenSize.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.resource.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.secondaryText),
                    splashRadius: 20,
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              if (widget.resource.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: screenSize.height * 0.35,
                  ),
                  child: Scrollbar(
                    controller: descriptionScrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: descriptionScrollController,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Text(
                          widget.resource.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.primaryText,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Tap a scholarship to visit its website',
                style: TextStyle(fontSize: 13, color: colors.secondaryText),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: widget.links.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No links available.',
                            style: TextStyle(color: colors.secondaryText),
                          ),
                        ),
                      )
                    : Scrollbar(
                        controller: linksScrollController,
                        thumbVisibility: true,
                        child: ListView.separated(
                          controller: linksScrollController,
                          shrinkWrap: true,
                          itemCount: widget.links.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final link = widget.links[index];
                            final hasUrl = link.url.trim().isNotEmpty;
                            return Semantics(
                              container: true,
                              button: true,
                              label: hasUrl
                                  ? 'Open ${link.name}'
                                  : '${link.name}, link unavailable',
                              hint: hasUrl
                                  ? 'Double tap to open the scholarship website.'
                                  : 'Double tap to hear that no link is available.',
                              onTap: () => widget.onOpenLink(context, link.url),
                              child: ExcludeSemantics(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.only(
                                    right: 12.0,
                                  ),
                                  title: Text(
                                    link.name,
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: link.deadline == null
                                      ? null
                                      : Text(
                                          'Deadline: ${MaterialLocalizations.of(context).formatMediumDate(link.deadline!)}',
                                        ),
                                  trailing: Icon(
                                    hasUrl
                                        ? Icons.open_in_new
                                        : Icons.link_off_outlined,
                                    size: 18,
                                    color: colors.secondaryText,
                                  ),
                                  onTap: () =>
                                      widget.onOpenLink(context, link.url),
                                ),
                              ),
                            );
                          },
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

class _OpportunityEditorDialog extends StatefulWidget {
  final _ScholarshipResource? initialResource;

  const _OpportunityEditorDialog({this.initialResource});

  @override
  State<_OpportunityEditorDialog> createState() =>
      _OpportunityEditorDialogState();
}

class _OpportunityEditorDialogState extends State<_OpportunityEditorDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController categoryController;
  late String selectedIcon;
  late List<_LinkEditorModel> linkEditors;

  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final target = widget.initialResource;
    titleController = TextEditingController(text: target?.title ?? '');
    descriptionController = TextEditingController(
      text: target?.description ?? '',
    );
    categoryController = TextEditingController(text: target?.category ?? '');
    selectedIcon = target?.iconKey ?? 'book';
    linkEditors =
        target?.links
            .map(
              (link) => _LinkEditorModel(
                name: link.name,
                url: link.url,
                deadline: _DateOnlyDeadline.formatForInput(link.deadline) ?? '',
              ),
            )
            .toList() ??
        [];
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    for (var editor in linkEditors) {
      editor.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialResource != null;
    final colors = AccessibilityColors.of(context);

    return AlertDialog(
      title: Text(isEditing ? 'Edit Opportunity' : 'Add Opportunity'),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
                TextFormField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedIcon,
                  decoration: const InputDecoration(labelText: 'Icon'),
                  items: _iconOptions.keys
                      .map(
                        (key) => DropdownMenuItem(
                          value: key,
                          child: Row(
                            children: [
                              Icon(
                                _iconOptions[key],
                                size: 18,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(key[0].toUpperCase() + key.substring(1)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedIcon = value);
                  },
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    const Text(
                      'Opportunity Links',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Link'),
                      onPressed: () =>
                          setState(() => linkEditors.add(_LinkEditorModel())),
                    ),
                  ],
                ),
                ...List.generate(linkEditors.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: linkEditors[i].nameController,
                                decoration: InputDecoration(
                                  labelText: 'Link Name #${i + 1}',
                                  isDense: true,
                                ),
                              ),
                              TextFormField(
                                controller: linkEditors[i].urlController,
                                decoration: InputDecoration(
                                  labelText: 'URL #${i + 1}',
                                  isDense: true,
                                ),
                              ),
                              TextFormField(
                                key: ValueKey('opportunity-link-deadline-$i'),
                                controller: linkEditors[i].deadlineController,
                                keyboardType: TextInputType.datetime,
                                decoration: InputDecoration(
                                  labelText:
                                      'Deadline #${i + 1} (YYYY-MM-DD, optional)',
                                  isDense: true,
                                ),
                                validator: (value) =>
                                    _DateOnlyDeadline.isValidOptional(value)
                                    ? null
                                    : 'Use YYYY-MM-DD',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: colors.destructive),
                          tooltip: 'Remove link ${i + 1}',
                          onPressed: () {
                            linkEditors[i].dispose();
                            setState(() => linkEditors.removeAt(i));
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          onPressed: () {
            if (!formKey.currentState!.validate()) return;

            final parsedLinks = linkEditors
                .where((e) => e.nameController.text.trim().isNotEmpty)
                .map(
                  (e) => _ScholarshipLink(
                    name: e.nameController.text.trim(),
                    url: e.urlController.text.trim(),
                    deadline: _DateOnlyDeadline.tryParse(
                      e.deadlineController.text,
                    ),
                  ),
                )
                .toList();

            final newResource = _ScholarshipResource(
              id: widget.initialResource?.id,
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              iconKey: selectedIcon,
              category: categoryController.text.trim(),
              links: parsedLinks,
            );

            Navigator.pop(context, newResource);
          },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

class _LinkEditorModel {
  final TextEditingController nameController;
  final TextEditingController urlController;
  final TextEditingController deadlineController;

  _LinkEditorModel({String name = '', String url = '', String deadline = ''})
    : nameController = TextEditingController(text: name),
      urlController = TextEditingController(text: url),
      deadlineController = TextEditingController(text: deadline);

  void dispose() {
    nameController.dispose();
    urlController.dispose();
    deadlineController.dispose();
  }
}

class _ScholarshipLink {
  final String name;
  final String url;
  final DateTime? deadline;

  const _ScholarshipLink({
    required this.name,
    required this.url,
    this.deadline,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'deadline': _DateOnlyDeadline.formatForInput(deadline),
  };

  factory _ScholarshipLink.fromJson(Map<String, dynamic> json) =>
      _ScholarshipLink(
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
        deadline: _DateOnlyDeadline.tryParse(json['deadline']),
      );
}

class _DateOnlyDeadline {
  static final RegExp _datePattern = RegExp(
    r'^([0-9]{4})-([0-9]{2})-([0-9]{2})$',
  );

  static DateTime? tryParse(Object? value) {
    if (value is! String) return null;
    final match = _datePattern.firstMatch(value.trim());
    if (match == null) return null;
    final parsed = DateTime.tryParse(value.trim());
    if (parsed == null ||
        parsed.year != int.parse(match.group(1)!) ||
        parsed.month != int.parse(match.group(2)!) ||
        parsed.day != int.parse(match.group(3)!)) {
      return null;
    }
    return DateUtils.dateOnly(parsed);
  }

  static bool isValidOptional(String? value) =>
      value == null || value.trim().isEmpty || tryParse(value) != null;

  static bool isExpired(DateTime? deadline, DateTime today) =>
      deadline != null && deadline.isBefore(DateUtils.dateOnly(today));

  static String? formatForInput(DateTime? deadline) {
    if (deadline == null) return null;
    final date = DateUtils.dateOnly(deadline);
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _ScholarshipResource {
  final int? id;
  final String title;
  final String description;
  final List<_ScholarshipLink> links;
  final String iconKey;
  final String category;

  const _ScholarshipResource({
    this.id,
    required this.title,
    required this.description,
    required this.links,
    this.iconKey = 'book',
    this.category = '',
  });

  IconData get icon => _iconOptions[iconKey] ?? Icons.auto_stories;

  String get favoriteId => id?.toString() ??
      '${category.trim().toLowerCase()}::${title.trim().toLowerCase()}';

  FavoriteEntry get favoriteEntry => FavoriteEntry(
    type: FavoriteType.opportunity,
    id: favoriteId,
    title: title,
    data: {'id': id, ...toJson()},
  );

  bool matchesKeyword(String query) {
    final keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) return true;

    final searchableText = <String>[
      title,
      category,
      description,
      ...links.map((link) => link.name),
    ].join(' ').toLowerCase();
    return searchableText.contains(keyword);
  }

  List<_ScholarshipLink> visibleLinks(DateTime today, bool includeExpired) =>
      includeExpired
      ? links
      : links
            .where((link) => !_DateOnlyDeadline.isExpired(link.deadline, today))
            .toList(growable: false);

  bool hasVisibleLinks(DateTime today, bool includeExpired) =>
      links.isEmpty || visibleLinks(today, includeExpired).isNotEmpty;

  DateTime? nextVisibleDeadline(DateTime today, bool includeExpired) {
    final deadlines = visibleLinks(
      today,
      includeExpired,
    ).map((link) => link.deadline).whereType<DateTime>().toList()..sort();
    return deadlines.isEmpty ? null : deadlines.first;
  }

  int compareDisplayedOrder(
    _ScholarshipResource other,
    DateTime today,
    bool includeExpired,
  ) {
    final deadline = nextVisibleDeadline(today, includeExpired);
    final otherDeadline = other.nextVisibleDeadline(today, includeExpired);
    if (deadline == null && otherDeadline == null)
      return title.compareTo(other.title);
    if (deadline == null) return 1;
    if (otherDeadline == null) return -1;
    return deadline.compareTo(otherDeadline);
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'iconKey': iconKey,
    'category': category,
    'links': links.map((l) => l.toJson()).toList(),
  };

  factory _ScholarshipResource.fromJson(Map<String, dynamic> json) =>
      _ScholarshipResource(
        id: json['id'] as int?,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        iconKey: json['iconKey'] as String? ?? 'book',
        category: json['category'] as String? ?? '',
        links:
            (json['links'] as List<dynamic>?)
                ?.map(
                  (item) =>
                      _ScholarshipLink.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
}

class _ResourceCard extends StatelessWidget {
  final _ScholarshipResource resource;
  final bool isAdmin;
  final DateTime? deadline;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ResourceCard({
    required this.resource,
    required this.isAdmin,
    required this.deadline,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: '${resource.title}. ${resource.description}',
                hint: 'Double tap to view opportunity details and links.',
                onTap: onTap,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onTap,
                  child: ExcludeSemantics(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            resource.icon,
                            color: colors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: colors.primaryText,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                resource.description,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colors.secondaryText,
                                      height: 1.4,
                                    ),
                              ),
                              if (deadline != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Deadline: ${MaterialLocalizations.of(context).formatMediumDate(deadline!)}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colors.secondaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: 'View opportunity details',
                          child: Icon(
                            Icons.chevron_right,
                            color: colors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            FavoriteToggleButton(favorite: resource.favoriteEntry),
            if (isAdmin) ...[
              const SizedBox(width: 6),
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: colors.action),
                    tooltip: 'Edit ${resource.title}',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: colors.destructive,
                    ),
                    tooltip: 'Delete ${resource.title}',
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
