import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter_hbb/common/widgets/setting_widgets.dart';
import 'package:flutter_hbb/common/widgets/toolbar.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../../models/platform_model.dart';

void _showSuccess() {
  showToast(translate("Successful"));
}

void _showError() {
  showToast(translate("Error"));
}

void setPermanentPasswordDialog(OverlayDialogManager dialogManager) async {
  final pw = await bind.mainGetPermanentPassword();
  final p0 = TextEditingController(text: pw);
  final p1 = TextEditingController(text: pw);
  var validateLength = false;
  var validateSame = false;
  dialogManager.show((setState, close, context) {
    submit() async {
      close();
      dialogManager.showLoading(translate("Waiting"));
      if (await gFFI.serverModel.setPermanentPassword(p0.text)) {
        dialogManager.dismissAll();
        _showSuccess();
      } else {
        dialogManager.dismissAll();
        _showError();
      }
    }

    return CustomAlertDialog(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.password_rounded, color: MyTheme.accent),
          Text(translate('Set your own password')).paddingOnly(left: 10),
        ],
      ),
      content: Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                labelText: translate('Password'),
              ),
              controller: p0,
              validator: (v) {
                if (v == null) return null;
                final val = v.trim().length > 5;
                if (validateLength != val) {
                  // use delay to make setState success
                  Future.delayed(Duration(microseconds: 1),
                      () => setState(() => validateLength = val));
                }
                return val
                    ? null
                    : translate('Too short, at least 6 characters.');
              },
            ).workaroundFreezeLinuxMint(),
            TextFormField(
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              decoration: InputDecoration(
                labelText: translate('Confirmation'),
              ),
              controller: p1,
              validator: (v) {
                if (v == null) return null;
                final val = p0.text == v;
                if (validateSame != val) {
                  Future.delayed(Duration(microseconds: 1),
                      () => setState(() => validateSame = val));
                }
                return val
                    ? null
                    : translate('The confirmation is not identical.');
              },
            ).workaroundFreezeLinuxMint(),
          ])),
      onCancel: close,
      onSubmit: (validateLength && validateSame) ? submit : null,
      actions: [
        dialogButton(
          'Cancel',
          icon: Icon(Icons.close_rounded),
          onPressed: close,
          isOutline: true,
        ),
        dialogButton(
          'OK',
          icon: Icon(Icons.done_rounded),
          onPressed: (validateLength && validateSame) ? submit : null,
        ),
      ],
    );
  });
}

void setTemporaryPasswordLengthDialog(
    OverlayDialogManager dialogManager) async {
  List<String> lengths = ['6', '8', '10'];
  String length = await bind.mainGetOption(key: "temporary-password-length");
  var index = lengths.indexOf(length);
  if (index < 0) index = 0;
  length = lengths[index];
  dialogManager.show((setState, close, context) {
    setLength(newValue) {
      final oldValue = length;
      if (oldValue == newValue) return;
      setState(() {
        length = newValue;
      });
      bind.mainSetOption(key: "temporary-password-length", value: newValue);
      bind.mainUpdateTemporaryPassword();
      Future.delayed(Duration(milliseconds: 200), () {
        close();
        _showSuccess();
      });
    }

    return CustomAlertDialog(
      title: Text(translate("Set one-time password length")),
      content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: lengths
              .map(
                (value) => Row(
                  children: [
                    Text(value),
                    Radio(
                        value: value, groupValue: length, onChanged: setLength),
                  ],
                ),
              )
              .toList()),
    );
  }, backDismiss: true, clickMaskDismiss: true);
}

void showServerSettings(OverlayDialogManager dialogManager,
    void Function(VoidCallback) setState) async {
  Map<String, dynamic> options = {};
  try {
    options = jsonDecode(await bind.mainGetOptions());
    // 로그인 시 저장된 ID 서버 및 키 정보가 있으면 우선적으로 활용
    final localIdServer = bind.mainGetLocalOption(key: 'idServerIp');
    final localKey = bind.mainGetLocalOption(key: 'idServerKey');
    if (localIdServer.isNotEmpty) {
      options['custom-rendezvous-server'] = localIdServer;
    }
    if (localKey.isNotEmpty) {
      options['key'] = localKey;
    }
  } catch (e) {
    print("Invalid server config: $e");
  }
  showServerSettingsWithValue(
      ServerConfig.fromOptions(options), dialogManager, setState);
}

void showServerSettingsWithValue(
    ServerConfig serverConfig,
    OverlayDialogManager dialogManager,
    void Function(VoidCallback)? upSetState) async {
  var isInProgress = false;

  // 로그인 시 설정된 값이 있는지 확인하여 필드 잠금 여부 결정
  final localIdServer = bind.mainGetLocalOption(key: 'idServerIp');
  final localKey = bind.mainGetLocalOption(key: 'idServerKey');
  final RxBool isLocked = true.obs;

  // Keep actual values in controllers even when locked
  final idCtrl = TextEditingController(text: serverConfig.idServer);
  final relayCtrl = TextEditingController(text: serverConfig.relayServer);
  final apiCtrl = TextEditingController(text: serverConfig.apiServer);
  final keyCtrl = TextEditingController(text: serverConfig.key);

  RxString idServerMsg = ''.obs;
  RxString relayServerMsg = ''.obs;
  RxString apiServerMsg = ''.obs;

  final controllers = [idCtrl, relayCtrl, apiCtrl, keyCtrl];
  final errMsgs = [
    idServerMsg,
    relayServerMsg,
    apiServerMsg,
  ];

  void unlockFields() {
    // Don't clear values - just unlock for manual editing
    isLocked.value = false;

  }




  dialogManager.show((setState, close, context) {
    Future<bool> submit() async {
      setState(() {
        isInProgress = true;
      });
      // 잠금 상태인 경우 로그인 시 받은 값을 사용하고, 아니면 입력 필드의 값을 사용
      final submitIdServer =
          isLocked.value ? localIdServer : idCtrl.text.trim();
      final submitKey = isLocked.value ? localKey : keyCtrl.text.trim();

      bool ret = await setServerConfig(
          null,
          errMsgs,
          ServerConfig(
              idServer: submitIdServer,
              relayServer: relayCtrl.text.trim(),
              apiServer: apiCtrl.text.trim(),
              key: submitKey));
      setState(() {
        isInProgress = false;
      });
      return ret;
    }

    Widget buildField(
        String label, TextEditingController controller, String errorMsg,
        {String? Function(String?)? validator,
        bool autofocus = false,
        bool isLockedField = false}) {
      if (isDesktop || isWeb) {
        return Obx(() => Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Text(label),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: isLockedField && isLocked.value
                      ? Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock, size: 16, color: Colors.green),
                              SizedBox(width: 8),
                              Text('설정됨 (로그인으로 자동 구성)',
                                  style: TextStyle(color: Colors.green[700])),
                            ],
                          ),
                        )
                      : TextFormField(
                          controller: controller,
                          decoration: InputDecoration(
                            errorText: errorMsg.isEmpty ? null : errorMsg,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 12),
                          ),
                          validator: validator,
                          autofocus: autofocus,
                          enabled: !isLocked.value,
                        ).workaroundFreezeLinuxMint(),
                ),
              ],
            ));
      }

      return Obx(() => isLockedField && isLocked.value
          ? Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.green),
                  SizedBox(width: 8),
                  Text('설정됨', style: TextStyle(color: Colors.green[700])),
                ],
              ),
            )
          : TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                errorText: errorMsg.isEmpty ? null : errorMsg,
              ),
              validator: validator,
              enabled: !isLocked.value,
            ).workaroundFreezeLinuxMint());
    }

    return CustomAlertDialog(
      title: Row(
            children: [
              Expanded(child: Text(translate('ID/Relay Server'))),
            ],
          ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 500),
        child: Form(
          child: Obx(() => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLocked.value)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 20, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '로그인으로 자동 구성된 설정입니다. 변경이 필요하시면 고객센터로 문의주세요.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.blue[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  buildField(translate('ID Server'), idCtrl, idServerMsg.value,
                      autofocus: true, isLockedField: true),
                  SizedBox(height: 8),
                  if (!isIOS && !isWeb) ...[
                    buildField(translate('Relay Server'), relayCtrl,
                        relayServerMsg.value),
                    SizedBox(height: 8),
                  ],
                  buildField(
                    translate('API Server'),
                    apiCtrl,
                    apiServerMsg.value,
                    validator: (v) {
                      if (v != null && v.isNotEmpty) {
                        if (!(v.startsWith('http://') ||
                            v.startsWith("https://"))) {
                          return translate("invalid_http");
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  buildField('Key', keyCtrl, '', isLockedField: true),
                  if (isInProgress)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(),
                    ),
                ],
              )),
        ),
      ),
      actions: [
        dialogButton('Cancel', onPressed: () {
          close();
        }, isOutline: true),
        dialogButton(
          'OK',
          onPressed: () async {
            if (await submit()) {
              close();
              showToast(translate('Successful'));
              upSetState?.call(() {});
            } else {
              showToast(translate('Failed'));
            }
          },
        ),
      ],
    );
  });
}

void setPrivacyModeDialog(
  OverlayDialogManager dialogManager,
  List<TToggleMenu> privacyModeList,
  RxString privacyModeState,
) async {
  dialogManager.dismissAll();
  dialogManager.show((setState, close, context) {
    return CustomAlertDialog(
      title: Text(translate('Privacy mode')),
      content: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: privacyModeList
              .map((value) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    title: value.child,
                    value: value.value,
                    onChanged: value.onChanged,
                  ))
              .toList()),
    );
  }, backDismiss: true, clickMaskDismiss: true);
}
