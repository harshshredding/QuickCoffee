import 'package:flutter/material.dart';

class Proposals extends StatefulWidget {
  ProposalsState createState() {
    return ProposalsState();
  }
}

class ProposalsState extends State<Proposals> {
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        Card(
          shape: BeveledRectangleBorder(
              borderRadius:
              BorderRadius.only(bottomRight: Radius.circular(20))),
          elevation: 5,
          child: Column(
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                color: Colors.brown,
                child: Text(
                  "DISCUSSION",
                  style: TextStyle(
                    color: Colors.brown.shade200,
                    fontSize: 15,
                    fontFamily: 'CarterOne',
                    letterSpacing: 3,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          textDirection: TextDirection.ltr,
                          children: <Widget>[
                            Container(
                                alignment: Alignment.centerLeft,
                                child: Text("BY :",
                                    style: TextStyle(
                                        color: Colors.brown.shade100,
                                        fontSize: 13)),
                                padding: EdgeInsets.only(
                                    left: 10, right: 10, top: 10, bottom: 5)),
                          ],
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Harsh Verma",
                            style: TextStyle(fontSize: 15),
                          ),
                          padding: EdgeInsets.only(
                              left: 10, right: 10, top: 0, bottom: 5),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "TOPIC :",
                            style: TextStyle(
                                color: Colors.brown.shade100, fontSize: 13),
                          ),
                          padding: EdgeInsets.only(
                              left: 10, right: 10, top: 10, bottom: 5),
                        ),
                        Container(
                          margin: EdgeInsets.only(right: 20),
                          alignment: Alignment.centerLeft,
                          child: Text("Lets talk about algorithm design asdasda sdadasdasd sda sdasd asdas dasd.",
                              style: TextStyle(fontSize: 15)),
                          padding: EdgeInsets.only(
                              left: 10, right: 10, top: 0, bottom: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    child: Container(
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.star,
                        size: 25,
                      ),
                      margin: EdgeInsets.only(
                          left: 10, right: 10, top: 10, bottom: 10),
                    ),
                  )
                ],
              )
            ],
          ),
          margin: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
        ),
        Card(
          shape: BeveledRectangleBorder(
              borderRadius:
              BorderRadius.only(bottomRight: Radius.circular(20))),
          elevation: 5,
          child: Column(
            children: <Widget>[
              Container(
                alignment: Alignment.center,
                color: Colors.brown,
                child: Text(
                  "DISCUSSION",
                  style: TextStyle(
                    color: Colors.brown.shade200,
                    fontSize: 15,
                    fontFamily: 'CarterOne',
                    letterSpacing: 3,
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          textDirection: TextDirection.ltr,
                          children: <Widget>[
                            Container(
                                alignment: Alignment.centerLeft,
                                child: Text("BY :",
                                    style: TextStyle(
                                        color: Colors.brown.shade100,
                                        fontSize: 13)),
                                padding: EdgeInsets.only(
                                    left: 10, right: 10, top: 10, bottom: 5)),
                          ],
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Harsh Verma",
                            style: TextStyle(fontSize: 15),
                          ),
                          padding: EdgeInsets.only(
                              left: 10, right: 10, top: 0, bottom: 5),
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "TOPIC :",
                            style: TextStyle(
                                color: Colors.brown.shade100, fontSize: 13),
                          ),
                          padding: EdgeInsets.only(
                              left: 10, right: 10, top: 10, bottom: 5),
                        ),
                        Container(
                          margin: EdgeInsets.only(right: 20),
                          alignment: Alignment.centerLeft,
                          child: Text("Lets talk about algorithm design asdasda sdadasdasd sda sdasd asdas dasd.",
                              style: TextStyle(fontSize: 15)),
                          padding: EdgeInsets.only(
                              left: 10, right: 10, top: 0, bottom: 10),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    alignment: Alignment.centerRight,
                    child: Container(
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.star,
                        size: 25,
                      ),
                      margin: EdgeInsets.only(
                          left: 10, right: 10, top: 10, bottom: 10),
                    ),
                  )
                ],
              )
            ],
          ),
          margin: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 10),
        )
      ],
    );
  }
}