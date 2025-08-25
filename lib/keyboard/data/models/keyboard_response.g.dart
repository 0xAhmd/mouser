// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyboard_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyboardResponse _$KeyboardResponseFromJson(Map<String, dynamic> json) =>
    KeyboardResponse(
      status: json['status'] as String,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$KeyboardResponseToJson(KeyboardResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'error': instance.error,
    };
