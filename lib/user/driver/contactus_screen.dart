import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactusScreen extends StatelessWidget {
  const ContactusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF004991),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Contact Us",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Color(0xFF004991),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left side: icon + text
                    Row(
                      children: [
                        IconButton(
                          icon: FaIcon(FontAwesomeIcons.facebook),
                       color: Color(0xFF004991),
                          iconSize: 30,
                          onPressed: () {
                            // Handle Facebook tap
                          },
                        ),
                    
                        const SizedBox(width: 12),
                        const Text(
                          "CurbShare",
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromRGBO(0, 73, 145, 1),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {},
                      child: const Icon(
                        Icons.navigate_next,
                        color: Color.fromRGBO(0, 73, 145, 1),
                      ),
                    )
                  ]),
              Divider(
                height: 17,
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left side: icon + text
                    Row(
                      children: [
                        IconButton(
                          icon: FaIcon(FontAwesomeIcons.instagram),
                        color: Color(0xFF004991),
                          iconSize: 30,
                          onPressed: () {
                            // Handle Facebook tap
                          },
                        ),
                    
                        const SizedBox(width: 12),
                        const Text(
                          "curbshare_cs",
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromRGBO(0, 73, 145, 1),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {},
                      child: const Icon(
                        Icons.navigate_next,
                        color: Color.fromRGBO(0, 73, 145, 1),
                      ),
                    )
                  ]),
              Divider(
                height: 17,
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left side: icon + text
                    Row(
                      children: [
                        IconButton(
                          icon: FaIcon(FontAwesomeIcons.xTwitter),
                          color: Color(0xFF004991),
                          iconSize: 30,
                          onPressed: () {
                            // Handle Facebook tap
                          },
                        ),
                    
                        const SizedBox(width: 12),
                        const Text(
                          "@curbshare_cs",
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromRGBO(0, 73, 145, 1),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {},
                      child: const Icon(
                        Icons.navigate_next,
                        color: Color.fromRGBO(0, 73, 145, 1),
                      ),
                    )
                  ]),
              Divider(
                height: 17,
              ),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left side: icon + text
                    Row(
                      children: [
                        IconButton(
                          icon: FaIcon(FontAwesomeIcons.telegram),
                   color: Color(0xFF004991),
                          iconSize: 30,
                          onPressed: () {
                            // Handle Facebook tap
                          },
                        ),
                    
                        const SizedBox(width: 12),
                        const Text(
                          "017 248 188",
                          style: TextStyle(
                            fontFamily: "Inter",
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromRGBO(0, 73, 145, 1),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {},
                      child: const Icon(
                        Icons.navigate_next,
                        color: Color.fromRGBO(0, 73, 145, 1),
                      ),
                    )
                  ]),
              Divider(
                height: 17,
              )
            ],
          ),
        ));
  }
}
