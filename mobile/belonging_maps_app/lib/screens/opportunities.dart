import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _primaryGreen = Color(0xFF2F5F3E);
const Color _pageBackground = Color(0xFFF9F5FA);

class OpportunitiesScreen extends StatelessWidget {
  const OpportunitiesScreen({super.key});

  static const List<_ScholarshipResource> _resources = [
    _ScholarshipResource(
      title: 'SOMOS Scholarships',
      description:
          'List of scholarships and opportunities for SOMOS, Ummah, and Ubuntu students.',
      links:[
        _ScholarshipLink(name: 'Spirit of Giving', url: 'https://www.winecountrygiftbaskets.com/information/scholarship.asp?srsltid=AfmBOorZirDGNmjoTYp0012FuEBOmL4sSxC54JfpgxXuKkD4UILa99Z9'),
        _ScholarshipLink(name: 'Hope College Scholarship', url: 'https://scholarships.sofiashope.org/?gad_source=1&gad_campaignid=22767042193&gbraid=0AAAAABJPZR5h7skRdflBR815h6GqSr5H3&gclid=Cj0KCQjwkILEBhDeARIsAL--pjzKdKWccMkaVu1HWZDRb4TKWMR4gNU3R0YXwwMBrmxCNCND_QyMenUaAqewEALw_wcB'),
        _ScholarshipLink(name: 'Nueva Generacion', url: 'https://californiafarmworkers.org/what-we-do/nueva-generacion-scholarship-program/'),
        _ScholarshipLink(name: 'Chicana Latina', url: 'https://chicanalatina.org/programs/scholarships/'),
        _ScholarshipLink(name: 'A Better Financial', url: 'https://www.afsusa.org/study-abroad/scholarships/?lead_source=mediacause&utm_source=google-grant&utm_medium=ad-grant&utm_campaign=scholarships&utm_content=general-scholarships&creative=685517597456&keyword=scholarship%20programs%20for%20high%20school&matchtype=b&network=g&device=c&gad_source=1&gad_campaignid=1997297492&gbraid=0AAAAADs0D_8MlXNKek0Qi4I2Wxq7i2bWu&gclid=Cj0KCQjwkILEBhDeARIsAL--pjzNab0jxarQa08KhoWTtkG2ymX5gr-wuKPMv3aluBhqkx29yWtnUeQaAmnMEALw_wcB'),
        //AICP Scholarship program link not working
        _ScholarshipLink(name: 'AICP Scholarship program', url: ''),
        //Double A Solution Scholarship link not working
        _ScholarshipLink(name: 'Double A Solution Scholarship', url: ''),
        _ScholarshipLink(name: 'Dreamer\'s Roadmap Scholarship', url: 'https://www.afsusa.org/study-abroad/scholarships/?lead_source=mediacause&utm_source=google-grant&utm_medium=ad-grant&utm_campaign=scholarships&utm_content=general-scholarships&creative=685517597456&keyword=scholarship%20programs%20for%20high%20school&matchtype=b&network=g&device=c&gad_source=1&gad_campaignid=1997297492&gbraid=0AAAAADs0D_8MlXNKek0Qi4I2Wxq7i2bWu&gclid=Cj0KCQjwkILEBhDeARIsAL--pjzNab0jxarQa08KhoWTtkG2ymX5gr-wuKPMv3aluBhqkx29yWtnUeQaAmnMEALw_wcB'),
        _ScholarshipLink(name: 'El Futuro Scholarship', url: 'https://sachcc.org/scholarship/'),
        _ScholarshipLink(name: 'Cien Amigos IME Becas', url: 'https://cienamigosedfund.org/'),
        _ScholarshipLink(name: 'BigSum Scholarship', url: 'https://bigsunathletics.com/'),
        _ScholarshipLink(name: 'Omega Phi Beta Foundation', url: 'http://opbfoundation.org/scholarships/'),
        _ScholarshipLink(name: 'Philip R. Nathe Scholarship', url: 'https://www.napervilledui.com/'),
        _ScholarshipLink(name: 'RealityHop Scholarship', url: 'https://www.ebcf.org/grants/scholarship-opportunities/?gad_source=1&gad_campaignid=20717852309&gbraid=0AAAAAo7ul86mzguYQHCn-pfdATO-KqZzJ&gclid=Cj0KCQjwkILEBhDeARIsAL--pjzfsfTzHC3VeH2aYDecNHThV5HRMWuPLfv9U5KFJF9ir6hnXrmrlCkaAt7mEALw_wcB'),
        _ScholarshipLink(name: 'A. Martin Latino Scholarship', url: 'https://www.financialaidfinder.com/antonia-martin-latino-educators-scholarship/'),
      ],
      icon: Icons.auto_stories,
    ),
    _ScholarshipResource(
      title: 'Ummah Scholarships',
      description:
          'List of scholarships and opportunities for Ummah students.',
      links:[
        _ScholarshipLink(name: 'MYLA Education Scholarship', url: 'https://www.mylawards.org/'),
        _ScholarshipLink(name: 'ISNA Scholarships', url: 'https://isna.net/scholarships'),
        _ScholarshipLink(name: 'SAJA Scholarships', url: 'https://www.saja.org/scholarships'),
        _ScholarshipLink(name: 'CAAP Scholarships', url: 'https://www.centeraap.org/grants/scholarships/'),
        _ScholarshipLink(name: 'Abdelkader Leadership Prize', url: 'https://abdelkaderproject.org/'),
        _ScholarshipLink(name: 'Barakat Senior Scholar', url: 'https://barakat.org/grants/#grants-overview'),
        _ScholarshipLink(name: 'Islamic Scholarship Fund', url: 'https://www.islamicscholarshipfund.org/create-your-own-scholarship'),
        _ScholarshipLink(name: 'Muslim Women Scholarship', url: 'https://www.scholarshipsforwomen.net/muslim/'),
        _ScholarshipLink(name: 'SALAM\'s Education Scholarship', url: 'https://salamcenter.org/education-scholarships/'),
        _ScholarshipLink(name: 'Manera West Scholarship', url: 'https://manarawest.org/resources/'),
        _ScholarshipLink(name: 'Amana Mutual Funds Scholarship', url: 'https://bigfuture.collegeboard.org/scholarships/amana-mutual-funds-scholarship'),
        _ScholarshipLink(name: 'The Islamic Seminary of America', url: 'https://islamicseminary.us/scholarships/'),
        _ScholarshipLink(name: 'SMUD Powering Futures', url: 'https://www.smud.org/In-Our-Community/College-Scholarships'),
        _ScholarshipLink(name: 'Sac Region Community Foundation', url: 'https://sacregcf.academicworks.com/opportunities'),
        _ScholarshipLink(name: 'MAX Scholarship Fund', url: 'https://maxscholars.org/scholarships'),
              
      ],

      icon: Icons.auto_stories,
    ),
    _ScholarshipResource(
      title: 'Ubuntu Scholarships',
      description:
          'List of scholarships and opportunities for Ubuntu students.',
      links:[
        _ScholarshipLink(name: 'Alpha Phi Alpha Fraternity', url: 'https://www.sacalphas.org/scholarship'),
        _ScholarshipLink(name: 'Sac Region Community Foundation', url: 'https://sacregcf.academicworks.com/opportunities'),
        _ScholarshipLink(name: 'SMUD Powering Futures', url: 'https://www.smud.org/In-Our-Community/College-Scholarships'),
        _ScholarshipLink(name: 'AMA Foundation Scholarship', url: 'https://amafoundation.org/'),
        _ScholarshipLink(name: 'Black Nurses Association', url: 'https://ccbna.org/scholarships/'),
        _ScholarshipLink(name: 'Ancestry History Makers', url: 'https://learnmore.scholarsapply.org/ancestry/'),
        _ScholarshipLink(name: 'Harry S. Truman Foundation', url: 'https://www.truman.gov/apply'),
        _ScholarshipLink(name: 'School House Connection', url: 'https://schoolhouseconnection.org/article/5-guides-to-help-homeless-college-students-in-california'),
        _ScholarshipLink(name: 'Marshall Scholarship', url: 'https://www.marshallscholarship.org/'),
        _ScholarshipLink(name: 'CA Homebuilding Foundation', url: 'https://www.mychf.org/college-scholarships'),
        _ScholarshipLink(name: 'ACS Scholarship in Chemistry', url: 'https://www.acs.org/education/acs-undergraduate-scholarship.html'),
        _ScholarshipLink(name: 'CalKIDS Scholarship', url: 'https://calkids.org/'),
        _ScholarshipLink(name: 'Congressional Black Caucus', url: 'https://www.cbcfinc.org/programs/scholarships/'),
        _ScholarshipLink(name: 'Square Root Academy', url: 'https://www.squarerootacademy.com/'),
        _ScholarshipLink(name: 'CIEF Scholarship in Architecture', url: 'https://www.cie.foundation/scholarships.html'),
        _ScholarshipLink(name: 'Frederick Roberts Scholarship', url: 'https://cablackcaucus.org/scholarships/'),

      ],
      icon: Icons.auto_stories,
    ),
  ];
    
    Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  void _showResourceInformation(
    BuildContext context,
    _ScholarshipResource resource,
  ) {
    final screenSize = MediaQuery.of(context).size;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: screenSize.width * 0.92,
            maxHeight: screenSize.height * 0.75,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a scholarship to visit its website',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: resource.links.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final link = resource.links[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          link.name,
                          style: const TextStyle(
                            color: _primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: _primaryGreen,
                        ),
                        onTap: () => _openLink(context, link.url),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: const Text(
          'Opportunities',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _resources.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final resource = _resources[index];
          return _ResourceCard(
            resource: resource,
            onTap: () => _showResourceInformation(context, resource),
          );
        },
      ),
    );
  }
}

class _ScholarshipLink {
  final String name;
  final String url;

  const _ScholarshipLink({required this.name, required this.url});
}

class _ScholarshipResource {
  final String title;
  final String description;
  final List<_ScholarshipLink> links;
  final IconData icon;

  const _ScholarshipResource({
    required this.title,
    required this.description,
    required this.links,
    required this.icon,
  });
}

class _ResourceCard extends StatelessWidget {
  final _ScholarshipResource resource;
  final VoidCallback onTap;

  const _ResourceCard({required this.resource, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'View information for ${resource.title}',
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(resource.icon, color: _primaryGreen, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        resource.description,
                        style: const TextStyle(
                          color: Colors.black54,
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
    );
  }
}
