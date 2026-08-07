import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seed_to_supper/api.dart';
import 'package:seed_to_supper/theme.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SeedToSupperApp());
}

class SeedToSupperApp extends StatelessWidget {
  const SeedToSupperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seed to Supper',
      debugShowCheckedModeBanner: false,
      theme: fstsTheme(),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> {
  final api = FstsApi();
  bool loading = true;
  bool signedIn = false;
  String displayName = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await api.loadToken();
    final name = await api.loadName();
    setState(() {
      signedIn = api.token != null && api.token!.isNotEmpty;
      displayName = name ?? '';
      loading = false;
    });
  }

  Future<void> _onAuthed(String token, String name) async {
    await api.saveToken(token);
    await api.saveName(name);
    setState(() {
      signedIn = true;
      displayName = name;
    });
  }

  Future<void> _logout() async {
    await api.saveToken(null);
    setState(() {
      signedIn = false;
      displayName = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: FstsColors.ochre)),
      );
    }
    if (!signedIn) {
      return LoginPage(api: api, onAuthed: _onAuthed);
    }
    return HomeShell(
      api: api,
      displayName: displayName,
      onLogout: _logout,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.api, required this.onAuthed});
  final FstsApi api;
  final Future<void> Function(String token, String name) onAuthed;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(text: 'grower@seedtosupper.demo');
  final password = TextEditingController(text: 'garden123');
  bool busy = false;
  String? error;

  Future<void> _demo() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await widget.api.demoLogin();
      final token = r['token'] as String?;
      final user = r['user'] as Map<String, dynamic>?;
      if (token == null) throw Exception(r['error'] ?? 'No token');
      await widget.onAuthed(token, user?['display_name']?.toString() ?? 'Grower');
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _login() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await widget.api.login(email.text.trim(), password.text);
      final token = r['token'] as String?;
      final user = r['user'] as Map<String, dynamic>?;
      if (token == null) throw Exception(r['error'] ?? 'No token');
      await widget.onAuthed(token, user?['display_name']?.toString() ?? 'Grower');
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF14281E), FstsColors.forest, FstsColors.forestDeep],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 40),
              Text('From Seed to Supper',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontFamily: 'serif',
                        color: FstsColors.cream,
                        fontWeight: FontWeight.w600,
                      )),
              const SizedBox(height: 8),
              const Text(
                'Every Seed Has a Story.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: FstsColors.ochre,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Field companion for iOS & Android — Today, plant, harvest, camera, journal. Same garden as the web app.',
                style: TextStyle(color: FstsColors.muted, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 28),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: busy ? null : _demo,
                      child: const Text('Enter demo garden'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: busy ? null : _login,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FstsColors.cream,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Sign in'),
                    ),
                    if (busy) ...[
                      const SizedBox(height: 16),
                      const Center(
                        child: CircularProgressIndicator(color: FstsColors.ochre),
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: Colors.redAccent)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.api,
    required this.displayName,
    required this.onLogout,
  });
  final FstsApi api;
  final String displayName;
  final VoidCallback onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;
  Map<String, dynamic>? today;
  List plantings = [];
  List journal = [];
  List photos = [];
  List features = [];
  String? message;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    setState(() => busy = true);
    try {
      final t = await widget.api.today();
      final g = await widget.api.growing();
      final j = await widget.api.journalList();
      final p = await widget.api.photos();
      final garden = await widget.api.garden();
      setState(() {
        today = t;
        plantings = (g['plantings'] as List?) ?? [];
        journal = (j['entries'] as List?) ?? [];
        photos = (p['photos'] as List?) ?? [];
        features = (garden['features'] as List?) ?? [];
      });
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _completeTask(int id, String title) async {
    try {
      await widget.api.completeTask(id);
      _toast('Done: $title');
      await refresh();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (file == null) return;
    setState(() => busy = true);
    try {
      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      await widget.api.uploadPhotoBase64(b64, caption: 'Field capture');
      _toast('Photo saved to garden');
      await refresh();
      setState(() => index = 2);
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _plantDialog() async {
    final name = TextEditingController(text: 'Tomato');
    final variety = TextEditingController();
    final qty = TextEditingController(text: '6');
    int? featureId = features.isNotEmpty
        ? int.tryParse(features.first['id'].toString())
        : null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FstsColors.forest,
        title: const Text('I’m planting'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Plant')),
              TextField(controller: variety, decoration: const InputDecoration(labelText: 'Variety')),
              TextField(controller: qty, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.plant(
        commonName: name.text.trim(),
        variety: variety.text.trim().isEmpty ? null : variety.text.trim(),
        quantity: int.tryParse(qty.text) ?? 1,
        featureId: featureId,
      );
      _toast('Planting recorded');
      await refresh();
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _harvestDialog() async {
    if (plantings.isEmpty) {
      _toast('No plantings yet');
      return;
    }
    int plantingId = int.parse(plantings.first['id'].toString());
    final amount = TextEditingController(text: '1');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FstsColors.forest,
        title: const Text('Add harvest'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: plantingId,
              items: plantings
                  .map((p) => DropdownMenuItem(
                        value: int.parse(p['id'].toString()),
                        child: Text('${p['common_name'] ?? ''} ${p['variety'] ?? ''}'),
                      ))
                  .toList(),
              onChanged: (v) => plantingId = v ?? plantingId,
            ),
            TextField(
              controller: amount,
              decoration: const InputDecoration(labelText: 'Amount (kg)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await widget.api.harvest(
        plantingId: plantingId,
        amount: double.tryParse(amount.text) ?? 1,
      );
      _toast('Harvest saved');
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _journalDialog() async {
    final body = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: FstsColors.forest,
        title: const Text('Journal'),
        content: TextField(
          controller: body,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'What happened in the garden?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || body.text.trim().isEmpty) return;
    try {
      await widget.api.journal(body.text.trim());
      _toast('Journal saved');
      await refresh();
      setState(() => index = 3);
    } catch (e) {
      _toast(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _TodayTab(
        today: today,
        busy: busy,
        onRefresh: refresh,
        onDone: _completeTask,
        onPlant: _plantDialog,
        onHarvest: _harvestDialog,
        onPhoto: _takePhoto,
        onJournal: _journalDialog,
      ),
      _GrowingTab(plantings: plantings, onPlant: _plantDialog, onHarvest: _harvestDialog),
      _CaptureTab(photos: photos, onCamera: _takePhoto, busy: busy),
      _JournalTab(entries: journal, onNew: _journalDialog),
      _MoreTab(
        displayName: widget.displayName,
        features: features,
        onLogout: widget.onLogout,
        onRefresh: refresh,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seed to Supper'),
            Text(
              widget.displayName.isEmpty ? 'In the garden' : widget.displayName,
              style: const TextStyle(fontSize: 13, color: FstsColors.muted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: FstsColors.ochre),
            onPressed: refresh,
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xEE0F1F17),
        indicatorColor: const Color(0x443E6B4E),
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), label: 'Today'),
          NavigationDestination(icon: Icon(Icons.eco_outlined), label: 'Growing'),
          NavigationDestination(icon: Icon(Icons.photo_camera_outlined), label: 'Capture'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Journal'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({
    required this.today,
    required this.busy,
    required this.onRefresh,
    required this.onDone,
    required this.onPlant,
    required this.onHarvest,
    required this.onPhoto,
    required this.onJournal,
  });
  final Map<String, dynamic>? today;
  final bool busy;
  final Future<void> Function() onRefresh;
  final Future<void> Function(int id, String title) onDone;
  final VoidCallback onPlant;
  final VoidCallback onHarvest;
  final VoidCallback onPhoto;
  final VoidCallback onJournal;

  @override
  Widget build(BuildContext context) {
    final tasksToday = (today?['tasks_today'] as List?) ?? [];
    final tasksSoon = (today?['tasks_five_days'] as List?) ?? [];
    final memory = today?['memory'] as Map<String, dynamic>?;

    return RefreshIndicator(
      color: FstsColors.ochre,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Today', style: TextStyle(color: FstsColors.ochre, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  today?['status_sentence']?.toString() ?? 'Everything is under control.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontFamily: 'serif',
                        color: FstsColors.cream,
                      ),
                ),
                const SizedBox(height: 8),
                Text(today?['weather_note']?.toString() ?? '', style: const TextStyle(color: FstsColors.muted)),
                Text('${today?['growing_count'] ?? 0} active plantings',
                    style: const TextStyle(color: FstsColors.sage)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChipBtn(label: 'Plant', onTap: onPlant),
              _ChipBtn(label: 'Harvest', onTap: onHarvest),
              _ChipBtn(label: 'Camera', onTap: onPhoto),
              _ChipBtn(label: 'Journal', onTap: onJournal),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Due today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          if (busy && today == null) const LinearProgressIndicator(color: FstsColors.ochre),
          ...tasksToday.map((t) => _TaskTile(t as Map<String, dynamic>, onDone)),
          if (tasksToday.isEmpty) const Text('Nothing pressing — enjoy the garden.', style: TextStyle(color: FstsColors.muted)),
          const SizedBox(height: 12),
          const Text('Next five days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ...tasksSoon.map((t) => _TaskTile(t as Map<String, dynamic>, onDone)),
          if (memory != null) ...[
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Garden memory', style: TextStyle(color: FstsColors.ochre)),
                  Text(memory['title']?.toString() ?? '',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  Text(memory['body']?.toString() ?? '', style: const TextStyle(color: FstsColors.muted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile(this.t, this.onDone);
  final Map<String, dynamic> t;
  final Future<void> Function(int id, String title) onDone;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(t['id'].toString()) ?? 0;
    final title = t['title']?.toString() ?? '';
    return _Card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                Text(
                  [t['due_on'], t['feature_name'], t['kind']].where((e) => e != null).join(' · '),
                  style: const TextStyle(color: FstsColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => onDone(id, title),
            icon: const Icon(Icons.check_circle, color: FstsColors.ochre),
          ),
        ],
      ),
    );
  }
}

class _GrowingTab extends StatelessWidget {
  const _GrowingTab({required this.plantings, required this.onPlant, required this.onHarvest});
  final List plantings;
  final VoidCallback onPlant;
  final VoidCallback onHarvest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            ElevatedButton(onPressed: onPlant, child: const Text('Plant')),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onHarvest,
              style: OutlinedButton.styleFrom(foregroundColor: FstsColors.cream),
              child: const Text('Harvest'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...plantings.map((p) {
          final m = p as Map<String, dynamic>;
          return _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m['common_name'] ?? ''}${m['variety'] != null ? ' — ${m['variety']}' : ''}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  [m['feature_name'], m['planted_on'] != null ? 'planted ${m['planted_on']}' : null, m['quantity'] != null ? '×${m['quantity']}' : null]
                      .where((e) => e != null)
                      .join(' · '),
                  style: const TextStyle(color: FstsColors.muted),
                ),
              ],
            ),
          );
        }),
        if (plantings.isEmpty)
          const Text('No active plantings', style: TextStyle(color: FstsColors.muted)),
      ],
    );
  }
}

class _CaptureTab extends StatelessWidget {
  const _CaptureTab({required this.photos, required this.onCamera, required this.busy});
  final List photos;
  final VoidCallback onCamera;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Garden photos', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('Snap beds, pests, harvests — saved to your garden record.',
                  style: TextStyle(color: FstsColors.muted)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: busy ? null : onCamera,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Take photo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...photos.map((p) {
          final m = p as Map<String, dynamic>;
          var url = m['url']?.toString() ?? '';
          if (url.startsWith('/')) url = 'https://mixapps.store$url';
          return _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (url.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(url, height: 160, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(height: 40, child: Text('Image unavailable'))),
                  ),
                if (m['caption'] != null) Text(m['caption'].toString()),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _JournalTab extends StatelessWidget {
  const _JournalTab({required this.entries, required this.onNew});
  final List entries;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton(onPressed: onNew, child: const Text('New journal entry')),
        const SizedBox(height: 12),
        ...entries.map((e) {
          final m = e as Map<String, dynamic>;
          return _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['created_at']?.toString() ?? '', style: const TextStyle(color: FstsColors.muted, fontSize: 13)),
                const SizedBox(height: 4),
                Text(m['body']?.toString() ?? '', style: const TextStyle(fontSize: 16, height: 1.35)),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab({
    required this.displayName,
    required this.features,
    required this.onLogout,
    required this.onRefresh,
  });
  final String displayName;
  final List features;
  final VoidCallback onLogout;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signed in as $displayName', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                'Full garden map (drag beds, season planner) is on the web companion.',
                style: TextStyle(color: FstsColors.muted),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final u = Uri.parse('https://mixapps.store/from-seed-to-supper/app/');
                  await launchUrl(u, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open web companion'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Beds on record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ...features.map((f) {
                final m = f as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('• ${m['name']} (${m['feature_type']})',
                      style: const TextStyle(color: FstsColors.muted)),
                );
              }),
              if (features.isEmpty)
                const Text('No features yet', style: TextStyle(color: FstsColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onLogout,
          style: OutlinedButton.styleFrom(foregroundColor: FstsColors.cream),
          child: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FstsColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33D9C68A)),
      ),
      child: child,
    );
  }
}

class _ChipBtn extends StatelessWidget {
  const _ChipBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: const Color(0x443E6B4E),
      labelStyle: const TextStyle(color: FstsColors.cream, fontWeight: FontWeight.w600),
    );
  }
}
