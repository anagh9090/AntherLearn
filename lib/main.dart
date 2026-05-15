import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AntherLearnApp());
}

class AntherLearnApp extends StatelessWidget {
  const AntherLearnApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AntherLearn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111111),
      ),
      home: const MainContainer(),
    );
  }
}

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});
  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  bool isStudyMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        child: isStudyMode
            ? GestureDetector(
                key: const ValueKey('study'),
                onLongPress: () => setState(() => isStudyMode = false),
                child: const AntherAcademyUI(),
              )
            : GestureDetector(
                key: const ValueKey('chat'),
                onTap: () => setState(() => isStudyMode = true),
                child: const TerminalChatUI(),
              ),
      ),
    );
  }
}

class AntherAcademyUI extends StatefulWidget {
  const AntherAcademyUI({super.key});
  @override
  State<AntherAcademyUI> createState() => _AntherAcademyUIState();
}

class _AntherAcademyUIState extends State<AntherAcademyUI> {
  int currentPage = 0;
  List<Map<String, String>> lessons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFromTxt();
  }

  Future<void> _loadFromTxt() async {
    try {
      final String fullText = await rootBundle.loadString('assets/book_content.txt');
      final RegExp chapterRegex = RegExp(r'(?=Chapter\s+\d+:)');
      final List<String> parts = fullText.split(chapterRegex);

      List<Map<String, String>> parsedLessons = [];
      for (var part in parts) {
        if (part.trim().isEmpty) continue;
        List<String> lines = part.trim().split('\n');
        String title = lines[0];
        String content = lines.sublist(1).join('\n').trim();
        parsedLessons.add({"t": title, "c": content});
      }

      setState(() {
        lessons = parsedLessons;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        lessons = [{"t": "Error", "c": "Could not find assets/book_content.txt"}];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: const Text("LINUX 4 KIDS", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("ACADEMY", style: TextStyle(color: Colors.white24, fontSize: 10)),
            Text("CH ${currentPage + 1}/${lessons.length}", style: const TextStyle(color: Colors.white24, fontSize: 10)),
          ]),
          const SizedBox(height: 30),
          Text(lessons[currentPage]['t']!, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Divider(color: Colors.greenAccent, thickness: 0.5),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Text(lessons[currentPage]['c']!, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.6)),
            ),
          ),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (currentPage > 0)
              OutlinedButton(
                onPressed: () => setState(() => currentPage--),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.greenAccent)),
                child: const Text("PREV", style: TextStyle(color: Colors.greenAccent)),
              ),
            const SizedBox(width: 20),
            if (currentPage < lessons.length - 1)
              ElevatedButton(
                onPressed: () => setState(() => currentPage++),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                child: const Text("NEXT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
          ]),
          const SizedBox(height: 30),
        ]),
      ),
    );
  }
}

class TerminalChatUI extends StatefulWidget {
  const TerminalChatUI({super.key});
  @override
  State<TerminalChatUI> createState() => _TerminalChatUIState();
}

class _TerminalChatUIState extends State<TerminalChatUI> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> logs = ["AntherOS TTY1 - Secure Link", "Ready..."];
  bool isAuthenticated = false;
  bool isWaitingForPass = false;
  String? myNodeID;

  final Map<String, String> userKeys = {"AN-01": "anther12", "AR-02": "arya99", "KR-03": "krish00"};

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  _loadIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => myNodeID = prefs.getString('node_id'));
  }

  void _handleInput(String input) {
    String cmd = input.trim();
    if (cmd.isEmpty) return;

    if (isWaitingForPass) {
      if (cmd == userKeys[myNodeID]) {
        setState(() { isAuthenticated = true; isWaitingForPass = false; logs.add("[AUTH] Success."); });
      } else {
        setState(() { logs.add("[AUTH] Denied."); isWaitingForPass = false; });
      }
    }
    else if (cmd.startsWith("set-alias ")) {
      String name = cmd.replaceFirst("set-alias ", "").trim().toLowerCase();
      String? id = (name == "anagh") ? "AN-01" : (name == "aryaman" ? "AR-02" : (name == "krish" ? "KR-03" : null));
      if (id != null) { 
        _saveIdentity(id); 
        setState(() => logs.add("[SYS] Identity: $id")); // Corrected: removed backslash
      }
    }
    else if (cmd == "sudo --access") {
      if (myNodeID != null) {
        setState(() { 
          logs.add("Pass for $myNodeID:"); // Corrected: removed backslash
          isWaitingForPass = true; 
        });
      }
    }
    else if (cmd == "clear") { setState(() => logs = ["Buffer Flushed."]); }
    else if (isAuthenticated) { _sendChat(cmd); }

    _controller.clear();
    _focusNode.requestFocus();
  }

  _saveIdentity(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('node_id', id);
    setState(() => myNodeID = id);
  }

  void _sendChat(String text) {
    _firestore.collection('messages').add({
      'text': text,
      'node': myNodeID ?? "GUEST",
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        Expanded(
          child: StreamBuilder(
            stream: _firestore.collection('messages').orderBy('timestamp', descending: false).snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              final chatDocs = snapshot.data?.docs ?? [];
              return ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  ...logs.map((l) => Text(l, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11))),
                  if (isAuthenticated)
                    ...chatDocs.map((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      // Corrected: proper interpolation for node and text
                      return Text("[${data['node']}] >> ${data['text']}", style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12));
                    }),
                ],
              );
            },
          ),
        ),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          obscureText: isWaitingForPass,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(
            // Corrected: using the literal '$' correctly at the end of the prompt
            prefixText: "${myNodeID ?? 'guest'}@anther:~\$ ", 
            prefixStyle: const TextStyle(color: Colors.greenAccent),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(15),
          ),
          onSubmitted: _handleInput,
        ),
      ]),
    );
  }
}
