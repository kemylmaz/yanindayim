import 'dart:convert';

import 'package:flutter/services.dart';

enum PfaNodeType { choice, info, widget, redirect }

class PfaOption {
  const PfaOption({required this.label, required this.next});

  final String label;
  final String next;

  factory PfaOption.fromJson(Map<String, dynamic> json) => PfaOption(
        label: json['label'] as String,
        next: json['next'] as String,
      );
}

class PfaNode {
  const PfaNode({
    required this.id,
    required this.type,
    this.title,
    this.subtitle,
    this.body,
    this.options,
    this.next,
    this.nextLabel,
    this.widget,
    this.params,
    this.route,
  });

  final String id;
  final PfaNodeType type;
  final String? title;
  final String? subtitle;
  final String? body;
  final List<PfaOption>? options;
  final String? next;
  final String? nextLabel;
  final String? widget;
  final Map<String, dynamic>? params;
  final String? route;

  factory PfaNode.fromJson(String id, Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = switch (typeStr) {
      'choice' => PfaNodeType.choice,
      'info' => PfaNodeType.info,
      'widget' => PfaNodeType.widget,
      'redirect' => PfaNodeType.redirect,
      _ => PfaNodeType.info,
    };

    final optionsRaw = json['options'] as List<dynamic>?;
    final options = optionsRaw
        ?.map((e) => PfaOption.fromJson(e as Map<String, dynamic>))
        .toList();

    return PfaNode(
      id: id,
      type: type,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      body: json['body'] as String?,
      options: options,
      next: json['next'] as String?,
      nextLabel: json['next_button'] as String? ?? json['nextLabel'] as String?,
      widget: json['widget'] as String?,
      params: json['params'] as Map<String, dynamic>?,
      route: json['route'] as String?,
    );
  }
}

class PfaFlow {
  const PfaFlow({required this.rootNodeId, required this.nodes});

  final String rootNodeId;
  final Map<String, PfaNode> nodes;

  PfaNode? operator [](String id) => nodes[id];
  PfaNode get root => nodes[rootNodeId]!;

  static Future<PfaFlow> load() async {
    final raw = await rootBundle.loadString('assets/pfa_flow.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final rootNodeId = json['rootNode'] as String;
    final nodesRaw = json['nodes'] as Map<String, dynamic>;
    final nodes = <String, PfaNode>{};
    nodesRaw.forEach((id, data) {
      nodes[id] = PfaNode.fromJson(id, data as Map<String, dynamic>);
    });
    return PfaFlow(rootNodeId: rootNodeId, nodes: nodes);
  }
}
