import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/accessibility_theme.dart';

// When authentication is implemented, replace this with actual user role check
final bool isAdmin = true;

const String _storageKey = 'opportunities_resources_v1';

const Map<String, IconData> _iconOptions = {
  'book': Icons.auto_stories,
  'school': Icons.school_outlined,
  'award': Icons.emoji_events_outlined,
  'career': Icons.work_outline,
  'public': Icons.public_outlined,
  'star': Icons.star_outline,
};

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  bool _isLoading = true;
  List<_ScholarshipResource> _resources = [];

  static const List<_ScholarshipResource> _defaultResources = [
    _ScholarshipResource(
      title: 'SOMOS Scholarships',
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
    _loadResources();
  }

  Future<void> _loadResources() async {
    final prefs = await SharedPreferences.getInstance();
    final storedJson = prefs.getString(_storageKey);

    if (storedJson != null && storedJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(storedJson);
        setState(() {
          _resources = decoded
              .map(
                (item) =>
                    _ScholarshipResource.fromJson(item as Map<String, dynamic>),
              )
              .toList();
          _isLoading = false;
        });
        return;
      } catch (_) {}
    }

    setState(() {
      _resources = List<_ScholarshipResource>.from(_defaultResources);
      _isLoading = false;
    });
    await _saveResources();
  }

  Future<void> _saveResources() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_resources.map((res) => res.toJson()).toList()),
    );
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
    showDialog<void>(
      context: context,
      builder: (dialogContext) =>
          _ResourceInfoDialog(resource: resource, onOpenLink: _openLink),
    );
  }

  void _showOpportunityDialog({int? index}) async {
    final isEditing = index != null;
    final target = isEditing ? _resources[index] : null;

    final result = await showDialog<_ScholarshipResource>(
      context: context,
      builder: (dialogContext) =>
          _OpportunityEditorDialog(initialResource: target),
    );

    if (result != null) {
      setState(() {
        if (isEditing) {
          _resources[index] = result;
        } else {
          _resources.add(result);
        }
      });

      await _saveResources();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Opportunity updated' : 'Opportunity added',
            ),
          ),
        );
      }
    }
  }

  void _deleteResource(int index) async {
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

    if (shouldDelete == true) {
      setState(() => _resources.removeAt(index));
      await _saveResources();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Opportunity deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AccessibilityColors.of(context);

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
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _resources.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final resource = _resources[index];
                return _ResourceCard(
                  resource: resource,
                  isAdmin: isAdmin,
                  onTap: () => _showResourceInformation(context, resource),
                  onDelete: () => _deleteResource(index),
                  onEdit: () => _showOpportunityDialog(index: index),
                );
              },
            ),
    );
  }
}

class _ResourceInfoDialog extends StatefulWidget {
  final _ScholarshipResource resource;
  final Function(BuildContext, String) onOpenLink;

  const _ResourceInfoDialog({required this.resource, required this.onOpenLink});

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                child: widget.resource.links.isEmpty
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
                          itemCount: widget.resource.links.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final link = widget.resource.links[index];
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
    selectedIcon = target?.iconKey ?? 'book';
    linkEditors =
        target?.links
            .map((link) => _LinkEditorModel(name: link.name, url: link.url))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  ),
                )
                .toList();

            final newResource = _ScholarshipResource(
              title: titleController.text.trim(),
              description: descriptionController.text.trim(),
              iconKey: selectedIcon,
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

  _LinkEditorModel({String name = '', String url = ''})
    : nameController = TextEditingController(text: name),
      urlController = TextEditingController(text: url);

  void dispose() {
    nameController.dispose();
    urlController.dispose();
  }
}

class _ScholarshipLink {
  final String name;
  final String url;

  const _ScholarshipLink({required this.name, required this.url});

  Map<String, dynamic> toJson() => {'name': name, 'url': url};

  factory _ScholarshipLink.fromJson(Map<String, dynamic> json) =>
      _ScholarshipLink(
        name: json['name'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}

class _ScholarshipResource {
  final String title;
  final String description;
  final List<_ScholarshipLink> links;
  final String iconKey;

  const _ScholarshipResource({
    required this.title,
    required this.description,
    required this.links,
    this.iconKey = 'book',
  });

  IconData get icon => _iconOptions[iconKey] ?? Icons.auto_stories;

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'iconKey': iconKey,
    'links': links.map((l) => l.toJson()).toList(),
  };

  factory _ScholarshipResource.fromJson(Map<String, dynamic> json) =>
      _ScholarshipResource(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        iconKey: json['iconKey'] as String? ?? 'book',
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
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ResourceCard({
    required this.resource,
    required this.isAdmin,
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
                hint: 'Double tap to view scholarship links.',
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                resource.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.secondaryText,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
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
