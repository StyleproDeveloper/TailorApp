import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PermissionDebugWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDebugInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final info = snapshot.data ?? {};
        final permissions = info['permissions'] as Map<String, bool>? ?? {};
        final roleId = info['roleId'];
        final roleName = info['roleName'];
        final rawJson = info['rawJson'] as String?;

        return Scaffold(
          appBar: AppBar(
            title: Text('Permission Debug Info'),
            backgroundColor: Colors.orange,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Role Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Role ID: ${roleId ?? "null"}'),
                Text('Role Name: ${roleName ?? "null"}'),
                SizedBox(height: 24),
                Text(
                  'Permissions (${permissions.length})',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                if (permissions.isEmpty)
                  Container(
                    padding: EdgeInsets.all(16),
                    color: Colors.red[50],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ NO PERMISSIONS FOUND!',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'This means role-based access will NOT work.',
                          style: TextStyle(color: Colors.red),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Possible causes:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('1. Backend did not return permissions'),
                        Text('2. Role not found in database'),
                        Text('3. Permissions not saved correctly'),
                      ],
                    ),
                  )
                else
                  ...permissions.entries.map((entry) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 4),
                      padding: EdgeInsets.all(8),
                      color: entry.value ? Colors.green[50] : Colors.grey[50],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text(
                            entry.value.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: entry.value ? Colors.green : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                SizedBox(height: 24),
                Text(
                  'Raw JSON',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.grey[100],
                  child: SelectableText(
                    rawJson ?? 'null',
                    style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getDebugInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final permissionsJson = prefs.getString('rolePermissions');
    final roleId = prefs.getInt('roleId');
    final roleName = prefs.getString('roleName');

    Map<String, bool> permissions = {};
    if (permissionsJson != null) {
      try {
        final decoded = jsonDecode(permissionsJson) as Map<String, dynamic>;
        permissions = decoded.map((key, value) => MapEntry(key, value as bool));
      } catch (e) {
        print('Error parsing: $e');
      }
    }

    return {
      'permissions': permissions,
      'roleId': roleId,
      'roleName': roleName,
      'rawJson': permissionsJson,
    };
  }
}

