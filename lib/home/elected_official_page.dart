import 'package:flutter/material.dart';
import 'header.dart';
import 'sample_data.dart';

class ElectedOfficialsPage extends StatefulWidget {
  const ElectedOfficialsPage({super.key});

  @override
  State<ElectedOfficialsPage> createState() => _ElectedOfficialsPageState();
}

class _ElectedOfficialsPageState extends State<ElectedOfficialsPage> {
  String _selectedAffiliation = 'USC';

  List<Official> get _filteredOfficials {
    return placeholderOfficials
        .where((o) => o.affiliation == _selectedAffiliation)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomHeader(
              title: 'Elected Officials',
              onBack: () => Navigator.pop(context),
            ),

            _buildAffiliationFilter(),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 22,
                ),
                itemCount: _filteredOfficials.length,
                itemBuilder: (context, index) {
                  return OfficialListItem(official: _filteredOfficials[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  //filter ng usc or ccis
  Widget _buildAffiliationFilter() {
    const affiliations = ['USC', 'CCIS'];
    const double outerRadius = 15.0;

    return Padding(
      padding: const EdgeInsets.only(top: 22, left: 25, right: 25),
      child: Container(
        height: 36,

        padding: const EdgeInsets.all(4),

        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(outerRadius),
        ),
        child: Row(
          children: affiliations.map((aff) {
            final isSelected = aff == _selectedAffiliation;
           
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAffiliation = aff;
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF5C6AA0)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    aff,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFECECEC)
                          : const Color(0xFF404040),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontFamily: 'Geist',
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// OfficialListItem
class OfficialListItem extends StatelessWidget {
  final Official official;

  const OfficialListItem({Key? key, required this.official}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        height: 114,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Left placeholder image area
            Container(
              width: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            const SizedBox(width: 15),

            // Official Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    official.position,
                    style: const TextStyle(
                      color: Color(0xFF404040),
                      fontSize: 20,
                      fontFamily: 'Geist',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    official.name,
                    style: TextStyle(
                      color: Color(0xFF747474),
                      fontSize: 12,
                      fontFamily: 'Geist',
                      height: 20 / 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${official.details}\n${official.party}',
                    style: TextStyle(
                      color: Color(0xFF747474),
                      fontSize: 12,
                      fontFamily: 'Geist',
                      height: 20 / 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Right arrow button
            Container(
              width: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF5C6AA0), // Blue button background
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
