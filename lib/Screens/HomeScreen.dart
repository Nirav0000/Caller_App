import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:direct_dialer/direct_dialer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Constent/Colors.dart';
import '../Controller/GetController.dart';
import '../Widget/widgets.dart';

class Grid_Screen extends StatefulWidget {
  Grid_Screen({
    Key? key,
    this.controller,
  }) : super(key: key);
  final ScrollController? controller;

  @override
  State<Grid_Screen> createState() => _Grid_ScreenState();
}

class _Grid_ScreenState extends State<Grid_Screen> {
  var homeController = Get.put(MyController());
  List<Map<String, dynamic>> _items = [];
  List? _contacts;
  bool DBdata = false;
  var DATA;
  var size, height, width;
  final _shoppingBox = Hive.box('GetContacts');
  List FevoritsItme = [];
  int clickCount = 0;
  List? uniquePersons;
  bool isFevorit = false;
  int _selectedIndex = -1;
  DirectDialer? dialer;

  @override
  void initState() {
    super.initState();
    setupDialer();
    getphoneDate();
    _refreshItems();
    loadSelectedItems();
  }


  Future<void> setupDialer() async => dialer = await DirectDialer.instance;

  Future<void> _createItem(Map<String, dynamic> newItem) async {
    await _shoppingBox.add(newItem);
    _refreshItems(); // update the UI
  }

  void getphoneDate() async {
    if (await FlutterContacts.requestPermission()) {
      _contacts = await FlutterContacts.getContacts(
          withThumbnail: true,
          withProperties: true,
          withPhoto: true,
          withAccounts: true);
    }
  }

  void _refreshItems() {
    final data = _shoppingBox.keys.map((key) {
      final value = _shoppingBox.get(key);
      return {
        "key": key,
        "name": value["name"],
        "phone": value['phone'],
        "image": value['image']
      };
    }).toList();

    setState(() {
      _items = data.toList();
      _items.forEach((e) {

        print('------name-----> ${e['name']}');
        print('------phone--------> ${e['phone']}');
      });
      storage.write('totalContacts', _items.length);
    });
  }

  Future<void> saveSelectedItems() async {
    // final prefs = await SharedPreferences.getInstance();
    // const key = 'selected_items';
    // ignore: prefer_null_aware_operators
    final value = FevoritsItme.map((item) =>item['phone']!=null? item['phone'].toString():null).join(',');
    storage.write("FevContacts", value);
    // await prefs.setString(key, value);
  }

  Future<void> loadSelectedItems() async {
    // final prefs = await SharedPreferences.getInstance();
    // const key = 'selected_items';
    // final value = prefs.getString(key) ?? '';
    final value = storage.read('FevContacts');
    final list = value.split(',').toList();
    final selectedList =
    _items.where((item) => list.contains(item['phone'])).toList();
    log('------------------>$selectedList');
    setState(() {
      FevoritsItme = selectedList ?? [];
      storage.write('FavriteContacts', FevoritsItme);
    });
  }
  Future<void> _deleteItem(int itemKey) async {
    await _shoppingBox.delete(itemKey);
    _refreshItems(); // update the UI

    // Display a snackbar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact delete successfully')));
  }

  @override
  Widget build(BuildContext context) {
    //uniquePersons = removeDuplicates(_filteredContacts);
    size = MediaQuery.of(context).size;
    height = size.height;
    width = size.width;
    // final provider = FavoriteProvider.of(context);
    // words_ = provider.words;
    // print("--------------------> fev list -------------> $FevoritsItme");
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return true;
      },
      child: Scaffold(
        backgroundColor: themeColor,
        body: Stack(
            children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                          top: 18, left: 8, right: 8, bottom: 8),
                      child: Container(
                        height: 45,
                        width: 45,
                        decoration: BoxDecoration(
                            color: white,
                            borderRadius: BorderRadius.circular(50)),
                        child: Obx(
                          () => Center(
                            child: IconButton(
                                onPressed: () {
                                  homeController.changeView();
                                },
                                icon: Image(
                                  image: AssetImage(
                                      homeController.isChangeGrid.value == false
                                          ? 'assets/images/grid.png'
                                          : 'assets/images/list.png'),
                                  height: 20,
                                )),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Wid_Con.textfield(
                          onChanged: (value) {
                            if (mounted) {
                              setState(() {});
                            }
                            return null;
                          },
                          filled: true,
                          filledColor: white,
                          hintText: "Search",
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Image.asset(
                              'assets/images/Search.png',
                              width: 3,
                              height: 3,
                            ),
                          )),
                    ),
                  ],
                ),
                Obx(
                  () =>  homeController.isChangeGrid.value == false?
                  Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: _items.isEmpty
                            ? Center(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image(image: AssetImage('assets/images/contactEmpty.png'),height: 100,),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        'No Contact Found',
                                        style: TextStyle(
                                            fontFamily: "Montserrat",
                                            fontSize: 17,
                                            fontWeight: FontWeight.w500,
                                            color: grey),
                                      ),

                                    ],
                                  ),
                                ),
                              )
                            :
                        // CupertinoScrollbar(
                        //   thickness: 5,
                        //       thumbVisibility: false,
                        //       child:
                              GridView.builder(
                                  controller: widget.controller,
                                physics: BouncingScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent:
                                              /*provider.isDark ? 150 :*/ 200,
                                          crossAxisSpacing: 15,
                                          mainAxisExtent: 250,
                                          mainAxisSpacing: 15),
                                  itemCount: _items.length,
                                  itemBuilder: (BuildContext context, int i) {
                                    _items.removeWhere((item) =>
                                        item['name'] == null && item['phone']);
                                    _items.sort((a, b) {
                                      String nameA = a['name'] ?? '';
                                      String nameB = b['name'] ?? '';

                                      // If either contact has no name, move it to the end
                                      if (nameA.isEmpty && nameB.isNotEmpty) {
                                        return 1;
                                      } else if (nameA.isNotEmpty &&
                                          nameB.isEmpty) {
                                        return -1;
                                      }

                                      // Otherwise, sort based on the names
                                      return nameA.compareTo(nameB);
                                    });
                                    final currentItem = _items[i];

                                    return GestureDetector(
                                      onTap: () async {

                                      },
                                      child: Container(
                                       decoration: BoxDecoration(
                                         color: white,
                                         borderRadius: BorderRadius.circular(10),
                                         boxShadow: [
BoxShadow(
  color: Colors.grey.shade300,
  offset: Offset(1, 1),
  spreadRadius: 1,
  blurRadius: 10
)
                                         ]
                                       ),
                                        child: Stack(
                                          children: [
                                            Column(
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(bottom: 10),
                                                    child: Stack(
                                                       alignment: Alignment.bottomCenter,
                                                      children: [
                                                        Container(
                                                        margin: EdgeInsets.only(left: 8,right:8,top: 8,bottom: 25),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey.shade100,
                                                            borderRadius: BorderRadius.circular(10),
                                                            image:  currentItem['image']!= null?DecorationImage(
                                                                image:MemoryImage(
                                                                    currentItem['image']),fit: BoxFit.cover):DecorationImage(

                                      image:AssetImage('assets/images/EmptyImage.png'),fit: BoxFit.cover)),
                                                      ),
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(100),
                                                          child: BackdropFilter(
                                                            filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                                            child: Container(
                                                              height: 70,
                                                              width: 70,
                                                              decoration: BoxDecoration(
                                                                  border: Border.all(color: black.withOpacity(0.1)),
                                                                  color: Colors.white.withOpacity(0.1),
                                                                  borderRadius: BorderRadius.circular(100)
                                                              ),
                                                              child: Center(
                                                                child: Text(
                                                                  currentItem['name'][0] ??
                                                                      '',
                                                                  overflow: TextOverflow
                                                                      .ellipsis,
                                                                  style: const TextStyle(
                                                                      fontFamily:
                                                                      "Montserrat",
                                                                      fontSize: 25,
                                                                      fontWeight:
                                                                      FontWeight
                                                                          .w500),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Container(

                                                    width: width / 2,
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          currentItem['name'] ??
                                                              '',
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                              fontFamily:
                                                                  "Montserrat",
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                        Text(
                                                          currentItem['phone'] ??
                                                              '',
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                              fontFamily:
                                                                  "Montserrat",
                                                              color: grey,
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600),
                                                        ),
                                                        Padding(
                                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                                          child: Container(
                                                            // color: grey,
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                                              children: [
                                                              InkWell(
                                                                splashColor: transparent,
                                                                  hoverColor: transparent,
                                                                   onTap: () {
                                                                     setState(() {
                                                                       // provider.toggleFavorite(currentItem);
                                                                       if (FevoritsItme.contains(
                                                                           currentItem)) {
                                                                         FevoritsItme.remove(
                                                                             currentItem);
                                                                       } else {
                                                                         FevoritsItme.add(
                                                                             currentItem);
                                                                       }
                                                                       saveSelectedItems();
                                                                     });
                                                                   },
                                                                  child: Image(
                                                                    image: AssetImage(FevoritsItme.contains(currentItem)?
                                                                    'assets/images/fevorit_nonfill.png':
                                                                    'assets/images/Fevorit.png'),
                                                                    height: 22,)),
                                                              InkWell(
                                                                  splashColor: transparent,
                                                                  hoverColor: transparent,
                                                                onTap: () async {
                                                                  await dialer?.dial(currentItem['phone']);
                                                                },
                                                                  child: Image(image: AssetImage('assets/images/call_icon.png'),height: 22,)),
                                                              InkWell(
                                                                splashColor: transparent,
                                                                hoverColor: transparent,
                                                                onTap: () {
                                                                  if(currentItem['phone']!=''){
                                                                    launchUrl(Uri.parse("sms:${currentItem['phone']}"));
                                                                  }

                                                                },
                                                                  child: Image(image: AssetImage('assets/images/message.png'),height: 23,)),
                                                              InkWell(
                                                                  splashColor: transparent,
                                                                  hoverColor: transparent,
                                                                  onTap: () {
                                                                    setState(() {
                                                                      // _deleteItem(currentItem['key']);
                                                                    });

                                                                  },
                                                                  child: Image(image: AssetImage('assets/images/more.png'),height: 18,)),
                                                              ],
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    )),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            // ),
                      ),
                    ),
                  ):Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: _items.isEmpty
                            ? Center(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image(image: AssetImage('assets/images/contactEmpty.png'),height: 100,),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'No Contact Found',
                                  style: TextStyle(
                                      fontFamily: "Montserrat",
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: grey),
                                ),

                              ],
                            ),
                          ),
                        )
                            :
                        // CupertinoScrollbar(
                        //   thickness: 5,
                        //       thumbVisibility: false,
                        //       child:
                        ListView.builder(
                          controller: widget.controller,
                          itemCount: _items.length,
                          physics: BouncingScrollPhysics(),
                          itemBuilder: (BuildContext context, int i) {
                            _items.removeWhere((item) =>
                            item['name'] == null && item['phone']);
                            _items.sort((a, b) {
                              String nameA = a['name'] ?? '';
                              String nameB = b['name'] ?? '';

                              // If either contact has no name, move it to the end
                              if (nameA.isEmpty && nameB.isNotEmpty) {
                                return 1;
                              } else if (nameA.isNotEmpty &&
                                  nameB.isEmpty) {
                                return -1;
                              }

                              // Otherwise, sort based on the names
                              return nameA.compareTo(nameB);
                            });
                            final currentItem = _items[i];

                            return GestureDetector(
                              onTap: () async {
                                setState(() {
                                  _selectedIndex = i;
                                });
                                // await dialer?.dial(currentItem['phone']);
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                    color: white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.grey.shade200,
                                          offset: Offset(1, 1),
                                          spreadRadius: 1,
                                          blurRadius: 10
                                      )
                                    ]
                                ),
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    AnimatedContainer(
                                      duration: Duration(milliseconds: 500),
                                      curve: Curves.fastOutSlowIn,
                                      height: _selectedIndex == i ?100:70,
                                      // color: grey,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                currentItem['image']!= null?
                                                CircleAvatar(

                                                  radius: 25,
                                                  backgroundImage: MemoryImage(currentItem['image']),
                                                ):CircleAvatar(
                                                radius: 25,
                                                                          backgroundImage: AssetImage('assets/images/EmptyImage.png'),
                                                                          ),
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 10,),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        Text(
                                                          currentItem['name'] ??
                                                              '',
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: const TextStyle(
                                                              fontFamily:
                                                              "Montserrat",
                                                              fontSize: 16,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w600),
                                                        ),
                                                        Text(
                                                          currentItem['phone'] ??
                                                              '',
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                              fontFamily:
                                                              "Montserrat",
                                                              color: grey,
                                                              fontSize: 13,
                                                              fontWeight:
                                                              FontWeight
                                                                  .w600),
                                                        ),

                                                        _selectedIndex == i?
                                                        Padding(
                                                          padding: const EdgeInsets.only(right: 10,top: 10),
                                                          child: Container(
                                                            // color: grey,
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: [
                                                                InkWell(
                                                                    splashColor: transparent,
                                                                    hoverColor: transparent,
                                                                    onTap: () {
                                                                      setState(() {
                                                                        // provider.toggleFavorite(currentItem);
                                                                        if (FevoritsItme.contains(
                                                                            currentItem)) {
                                                                          FevoritsItme.remove(
                                                                              currentItem);
                                                                        } else {
                                                                          FevoritsItme.add(
                                                                              currentItem);
                                                                        }
                                                                        saveSelectedItems();
                                                                      });
                                                                    },
                                                                    child: Image(
                                                                      image: AssetImage(FevoritsItme.contains(currentItem)?
                                                                      'assets/images/fevorit_nonfill.png':
                                                                      'assets/images/Fevorit.png'),
                                                                      height: 22,)),
                                                                InkWell(
                                                                    splashColor: transparent,
                                                                    hoverColor: transparent,
                                                                    onTap: () async {
                                                                      await dialer?.dial(currentItem['phone']);
                                                                    },
                                                                    child: Image(image: AssetImage('assets/images/call_icon.png'),height: 22,)),
                                                                InkWell(
                                                                    splashColor: transparent,
                                                                    hoverColor: transparent,
                                                                    onTap: () {
                                                                      if(currentItem['phone']!=''){
                                                                        launchUrl(Uri.parse("sms:${currentItem['phone']}"));
                                                                      }

                                                                    },
                                                                    child: Image(image: AssetImage('assets/images/message.png'),height: 23,)),
                                                                InkWell(
                                                                    splashColor: transparent,
                                                                    hoverColor: transparent,
                                                                    onTap: () {
                                                                      setState(() {
                                                                        // _deleteItem(currentItem['key']);
                                                                      });

                                                                    },
                                                                    child: Image(image: AssetImage('assets/images/more.png'),height: 18,)),
                                                              ],
                                                            ),
                                                          ),
                                                        ):Container()
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // ),
                      ),
                    ),
                  ),
                ),
                // widget.combinedList != null ?
                // Text(widget.combinedList.toString() ?? '') : Container()
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
