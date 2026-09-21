import 'package:flutter/material.dart';
import '../core/theme/colores_app.dart';

class NavItem {
  final String label;
  final IconData icon;
  final Widget Function(BuildContext) screenBuilder;
  final int? badge;

  NavItem({
    required this.label,
    required this.icon,
    required this.screenBuilder,
    this.badge,
  });
}

class NavSection {
  final String? title;
  final List<NavItem> items;

  NavSection({this.title, required this.items});
}

class AppShell extends StatefulWidget {
  final String appTitle;
  final String roleLabel;
  final String userName;
  final List<NavSection> sections;
  final VoidCallback onLogout;

  const AppShell({
    super.key,
    required this.appTitle,
    required this.roleLabel,
    required this.userName,
    required this.sections,
    required this.onLogout,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  late List<NavItem> _flatItems;

  @override
  void initState() {
    super.initState();
    _flatItems = widget.sections.expand((s) => s.items).toList();
  }

  void _selectIndex(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = _flatItems[_selectedIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final movil = constraints.maxWidth < 900;

        Widget sidebar({required bool enDrawer}) => _Sidebar(
              appTitle: widget.appTitle,
              roleLabel: widget.roleLabel,
              sections: widget.sections,
              selectedIndex: _selectedIndex,
              onSelect: (i) {
                _selectIndex(i);
                if (enDrawer) Navigator.of(context).pop();
              },
              onLogout: widget.onLogout,
            );

        final contenido = Container(
          color: AppColors.background,
          child: currentItem.screenBuilder(context),
        );

        if (movil) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              scrolledUnderElevation: 0,
              shape: const Border(bottom: BorderSide(color: Color(0xFFE7E7EC))),
              title: Text(
                currentItem.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              actions: [
                _Avatar(userName: widget.userName),
                const SizedBox(width: 14),
              ],
            ),
            drawer: Drawer(
              width: 290,
              backgroundColor: AppColors.primary,
              child: sidebar(enDrawer: true),
            ),
            body: contenido,
          );
        }

        return Scaffold(
          body: Row(
            children: [
              SizedBox(width: 250, child: sidebar(enDrawer: false)),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(title: currentItem.label, userName: widget.userName),
                    Expanded(child: contenido),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  final String userName;
  const _Avatar({required this.userName});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 15,
      backgroundColor: AppColors.primary,
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final String userName;

  const _TopBar({required this.title, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7EC))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                const Text('En línea', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _Avatar(userName: userName),
          const SizedBox(width: 8),
          Text(userName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String appTitle;
  final String roleLabel;
  final List<NavSection> sections;
  final int selectedIndex;
  final void Function(int) onSelect;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.appTitle,
    required this.roleLabel,
    required this.sections,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    int runningIndex = 0;

    return Container(
      color: AppColors.primary,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset(
                        'assets/images/logo_colmas.jpg',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(Icons.school_rounded, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(roleLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: sections.map((section) {
                  final items = section.items.map((item) {
                    final index = runningIndex++;
                    final selected = index == selectedIndex;
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        onTap: () => onSelect(index),
                        selected: selected,
                        selectedTileColor: Colors.white.withOpacity(0.12),
                        leading: Icon(item.icon, color: Colors.white, size: 20),
                        title: Text(item.label, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        trailing: item.badge != null
                            ? CircleAvatar(radius: 9, backgroundColor: AppColors.danger, child: Text('${item.badge}', style: const TextStyle(fontSize: 10, color: Colors.white)))
                            : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    );
                  }).toList();

                  if (section.title != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                          child: Text(section.title!.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                        ),
                        ...items,
                      ],
                    );
                  }
                  return Column(children: items);
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}