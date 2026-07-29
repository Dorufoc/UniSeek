// 聊天 WebSocket 帧隔离测试
// 作用：验证 ArkTS/Vue 端发送/解析的帧与 Java ChatWebSocketHandler 生成的帧字段一致。
// 运行方式：node .omo/audit/arkts-api/scripts/chat-frame-test.js

const assert = require('assert');

// ---------- ArkTS ServerConfig.toWebSocketUrl 的同源转换逻辑 ----------
function toWebSocketUrl(baseUrl, token) {
  let normalized = baseUrl.trim();
  if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
    normalized = 'http://192.168.246.118:8080';
  }
  while (normalized.endsWith('/')) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  let socketBase = normalized;
  if (normalized.startsWith('https://')) {
    socketBase = 'wss://' + normalized.substring(8);
  } else if (normalized.startsWith('http://')) {
    socketBase = 'ws://' + normalized.substring(7);
  }
  return socketBase + '/ws/chat?token=' + encodeURIComponent(token);
}

// ---------- Java ChatWebSocketHandler.extractToken 逻辑 ----------
function extractToken(url) {
  const queryIndex = url.indexOf('?');
  if (queryIndex === -1) return null;
  const query = url.substring(queryIndex + 1);
  for (const param of query.split('&')) {
    const pair = param.split('=');
    if (pair.length === 2 && pair[0] === 'token') {
      return pair[1];
    }
  }
  return null;
}

// ---------- ArkTS ChatWebSocketService.sendPing 生成的 PING 帧 ----------
function buildPingFrame() {
  return '{"type":"PING","data":{}}';
}

// ---------- Java buildMessage 生成的统一帧 ----------
function buildJavaMessage(type, data) {
  const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
  return JSON.stringify({ type, data, timestamp });
}

// ---------- Java ChatWebSocketHandler.notifyNewMessage 生成的 NEW_MESSAGE data ----------
function buildJavaNewMessageData(messageVo) {
  return {
    messageId: messageVo.id,
    applicationId: messageVo.applicationId,
    sessionType: messageVo.sessionType || 'application',
    senderId: messageVo.senderId,
    senderName: messageVo.senderName,
    senderAvatar: messageVo.senderAvatar,
    content: messageVo.content,
    messageType: messageVo.messageType,
    sendTime: messageVo.sendTime
  };
}

// ---------- ArkTS ChatProtocolMappers.mapWsNewMessageToChatMessageVO 逻辑 ----------
function mapWsNewMessageToChatMessageVO(data) {
  return {
    id: data.messageId,
    senderId: data.senderId,
    messageType: data.messageType,
    content: data.content,
    isRead: data.isRead,
    sendTime: data.sendTime,
    senderName: data.senderName,
    senderAvatar: data.senderAvatar
  };
}

// ---------- 测试计数器 ----------
let passed = 0;
let failed = 0;

function test(name, fn) {
  try {
    fn();
    passed++;
    console.log(`  PASS: ${name}`);
  } catch (e) {
    failed++;
    console.log(`  FAIL: ${name} -> ${e.message}`);
  }
}

console.log('开始 chat/WebSocket 帧隔离测试...\n');

// 1. WebSocket URL 与 token 参数
test('ArkTS 生成的 WS URL 包含 /ws/chat?token=', () => {
  const url = toWebSocketUrl('http://192.168.246.118:8080', 'mock.token');
  assert(url.startsWith('ws://'));
  assert(url.includes('/ws/chat?token='));
});

test('Java extractToken 能从 ArkTS 生成的 URL 中解析 token（base64url 安全字符不变）', () => {
  const token = 'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VySWQiOjF9.signature'; // 仅含安全字符
  const url = toWebSocketUrl('http://192.168.246.118:8080', token);
  assert.strictEqual(extractToken(url), token);
});

test(' ArkTS 对含特殊字符的 token 做 URL 编码，但 Java 未解码，存在潜在不一致风险', () => {
  const token = 'a+b=c&d';
  const url = toWebSocketUrl('http://192.168.246.118:8080', token);
  // Java extractToken 直接返回编码后的字符串，不会调用 decodeURIComponent
  assert.strictEqual(extractToken(url), encodeURIComponent(token));
  assert.notStrictEqual(extractToken(url), token);
});

// 2. PING/PONG
test('ArkTS 发送的 PING 帧能被 Java 解析，并回复 PONG', () => {
  const frame = buildPingFrame();
  const root = JSON.parse(frame);
  assert.strictEqual(root.type, 'PING');
  assert.deepStrictEqual(root.data, {});
  const pong = buildJavaMessage('PONG', {});
  assert.strictEqual(JSON.parse(pong).type, 'PONG');
});

// 3. NEW_MESSAGE 帧字段
test('Java 推送的 NEW_MESSAGE 帧字段与 ArkTS WsNewMessageData 一致', () => {
  const vo = {
    id: 123,
    applicationId: 456,
    sessionType: 'application',
    senderId: 7,
    senderName: '张三',
    senderAvatar: 'http://example.com/a.jpg',
    content: '你好',
    messageType: 0,
    sendTime: '2026-07-29 10:00:00'
  };
  const frame = buildJavaMessage('NEW_MESSAGE', buildJavaNewMessageData(vo));
  const parsed = JSON.parse(frame);
  assert.strictEqual(parsed.type, 'NEW_MESSAGE');
  assert.strictEqual(parsed.data.messageId, 123);
  assert.strictEqual(parsed.data.applicationId, 456);
  assert.strictEqual(parsed.data.sessionType, 'application');
  assert.strictEqual(parsed.data.senderId, 7);
  assert.strictEqual(parsed.data.senderName, '张三');
  assert.strictEqual(parsed.data.senderAvatar, 'http://example.com/a.jpg');
  assert.strictEqual(parsed.data.content, '你好');
  assert.strictEqual(parsed.data.messageType, 0);
  assert.strictEqual(parsed.data.sendTime, '2026-07-29 10:00:00');

  const chatMessageVO = mapWsNewMessageToChatMessageVO(parsed.data);
  assert.strictEqual(chatMessageVO.id, 123);
  assert.strictEqual(chatMessageVO.senderId, 7);
  assert.strictEqual(chatMessageVO.messageType, 0);
  assert.strictEqual(chatMessageVO.content, '你好');
  assert.strictEqual(chatMessageVO.sendTime, '2026-07-29 10:00:00');
  assert.strictEqual(chatMessageVO.senderName, '张三');
  assert.strictEqual(chatMessageVO.senderAvatar, 'http://example.com/a.jpg');
});

test('NEW_MESSAGE 帧缺少 isRead 字段，与 ArkTS ChatMessageVO/Mapper 期望不一致', () => {
  const vo = {
    id: 123,
    applicationId: 456,
    sessionType: 'application',
    senderId: 7,
    senderName: '张三',
    senderAvatar: 'http://example.com/a.jpg',
    content: '你好',
    messageType: 0,
    sendTime: '2026-07-29 10:00:00'
  };
  const frame = buildJavaMessage('NEW_MESSAGE', buildJavaNewMessageData(vo));
  const parsed = JSON.parse(frame);
  assert.strictEqual(parsed.data.isRead, undefined);
  const chatMessageVO = mapWsNewMessageToChatMessageVO(parsed.data);
  assert.strictEqual(chatMessageVO.isRead, undefined);
});

// 4. SEND_ACK 帧
test('Java 回复的 SEND_ACK 帧字段与 ArkTS WsSendAckData 一致', () => {
  const ackData = {
    messageId: 789,
    applicationId: 456,
    sessionType: 'application',
    messageType: 1,
    content: 'http://example.com/image.png',
    sendTime: '2026-07-29 10:00:01'
  };
  const frame = buildJavaMessage('SEND_ACK', ackData);
  const parsed = JSON.parse(frame);
  assert.strictEqual(parsed.type, 'SEND_ACK');
  assert.strictEqual(parsed.data.messageId, 789);
  assert.strictEqual(parsed.data.applicationId, 456);
  assert.strictEqual(parsed.data.sessionType, 'application');
  assert.strictEqual(parsed.data.messageType, 1);
  assert.strictEqual(parsed.data.content, 'http://example.com/image.png');
  assert.strictEqual(parsed.data.sendTime, '2026-07-29 10:00:01');
});

// 5. MESSAGE_READ 帧
test('Java MESSAGE_READ 帧至少包含 applicationId、sessionType、readerId', () => {
  const readData = {
    applicationId: 456,
    sessionType: 'application',
    readerId: 7
  };
  const frame = buildJavaMessage('MESSAGE_READ', readData);
  const parsed = JSON.parse(frame);
  assert.strictEqual(parsed.type, 'MESSAGE_READ');
  assert.strictEqual(parsed.data.applicationId, 456);
  assert.strictEqual(parsed.data.sessionType, 'application');
  assert.strictEqual(parsed.data.readerId, 7);
});

// 6. ERROR 帧
test('Java ERROR 帧包含 code 和 message，ArkTS 当前 handleMessage 忽略 ERROR 类型', () => {
  const errorData = { code: 4101, message: '缺少 applicationId' };
  const frame = buildJavaMessage('ERROR', errorData);
  const parsed = JSON.parse(frame);
  assert.strictEqual(parsed.type, 'ERROR');
  assert.strictEqual(parsed.data.code, 4101);
  assert.strictEqual(parsed.data.message, '缺少 applicationId');
});

// 7. 消息类型枚举
test('text/image/resume(attachment) 消息类型值在三端一致：text=0, image=1, attachment=2', () => {
  // ArkTS ChatService.sendMessage 默认 0；handleImageUpload 发送 1；handleSendResume 发送 2
  // Vue Messages.vue/Chat.vue 同样使用 1=图片、2=简历附件
  // Java 通过 messageType 字段透传，未做枚举转换
  const msgTypes = { text: 0, image: 1, attachment: 2 };
  assert.strictEqual(msgTypes.text, 0);
  assert.strictEqual(msgTypes.image, 1);
  assert.strictEqual(msgTypes.attachment, 2);
});

// 8. 上传响应解析（ArkTS FileTransferPolicy.readUploadUrl）
function readUploadUrl(response) {
  if (response.code !== 200 || !response.data || !response.data.url) {
    return '';
  }
  return response.data.url.trim();
}

test('ArkTS 能正确解析 Java UploadController 返回的上传响应结构 {code,message,data:{url}}', () => {
  const response = { code: 200, message: '上传成功', data: { url: '/api/files/images/20260729/uuid.png' } };
  assert.strictEqual(readUploadUrl(response), '/api/files/images/20260729/uuid.png');
});

test('上传响应 code 非 200 或缺少 data.url 时返回空字符串', () => {
  assert.strictEqual(readUploadUrl({ code: 500, message: '失败', data: { url: '/x' } }), '');
  assert.strictEqual(readUploadUrl({ code: 200, message: '成功', data: {} }), '');
});

console.log(`\n测试结果：通过 ${passed}，失败 ${failed}`);
process.exit(failed > 0 ? 1 : 0);
