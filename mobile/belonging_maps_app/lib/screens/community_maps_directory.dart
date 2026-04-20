import 'package:flutter/material.dart';
import '/screens/somos_community_map.dart';
import '/screens/ummah_community_map.dart';
import '/screens/ubuntu_community_map.dart';

class CommunityMapsDirectory extends StatelessWidget {
  const CommunityMapsDirectory({super.key});

  @override
  Widget build(BuildContext context) {

    //Query for screen size to control dynamic sizing of buttons
    double screenWidth = MediaQuery.sizeOf(context).width;
    double buttonWidth = screenWidth * (0.85);
    if (buttonWidth >= 401){
      buttonWidth = 400;
    }
    double buttonHeight = buttonWidth/3;

    //Padding between buttons
    double paddingHeight = 40;

    //Body text size and color
    Color bodyTextColor = Colors.black;
    double bodyTextSize = 18;

    //Head text size and color
    Color headTextColor = Colors.black;
    double headTextSize = 28;

    return Scaffold(
      appBar: AppBar(
        title: Text('Community Maps',
        style: TextStyle(
          color: headTextColor,
          fontWeight: FontWeight.w700,
          fontSize: headTextSize,
        ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            //Somos text and button
            Text(
              'SOMOS Community Map',
              style: TextStyle(
                color: bodyTextColor,
                fontSize: bodyTextSize,
                fontWeight: FontWeight.w700,
              )
            ),
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SomosCommunityMap()),
                );
              },
              child: ClipRRect(borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/somoscommunityheader.png',
                width: buttonWidth,
                height: buttonHeight,
                fit: BoxFit.cover,
              ))
            ),
            ),
            SizedBox(height: paddingHeight), //Padding
            
            //Ummah text and button
            Text(
              'UMMAH Community Map',
              style: TextStyle(
                color: bodyTextColor,
                fontSize: bodyTextSize,
                fontWeight: FontWeight.w700,
              )
            ),
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UmmahCommunityMap()),
                );
              },
              child: ClipRRect(borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/ummahcommunityheader.png',
                width: buttonWidth,
                height: buttonHeight,
                fit: BoxFit.cover,
              ))
            ),
            ),
            SizedBox(height: paddingHeight), //Padding

            //Ubuntu text and button
            Text(
              'UBUNTU Community Map',
              style: TextStyle(
                color: bodyTextColor,
                fontSize: bodyTextSize,
                fontWeight: FontWeight.w700,
              )
            ),
            SizedBox(
              width: buttonWidth,
              height: buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UbuntuCommunityMap()),
                );
              },
              child: ClipRRect(borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/ubuntucommunityheader.png',
                width: buttonWidth,
                height: buttonHeight,
                fit: BoxFit.cover,
              ))
            ),
            ),
            const SizedBox(height: 20), //Padding
          ],
        ),
      ),
    );
  }
}