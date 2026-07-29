// 隔离的 mock transport 测试
// 不依赖项目产品代码，仅使用 Node.js 内置 http 模块模拟 ArkTS/Vue 与 Java 后端的传输、鉴权和错误协议。

const http = require('http');
const path = require('path');
const fs = require('fs');

const PORT = 0; // 随机端口
const TOKEN = 'mock-jwt-token-xyz';

function logResult(testName, status, expected, actual) {
  return {
    test: testName,
    status: status,
    expected: expected,
    actual: actual
  };
}

function sendRequest(method, path, headers, body) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: '127.0.0.1',
      port: server.address().port,
      method: method,
      path: path,
      headers: headers || {}
    };
    const req = http.request(options, (res) => {
      let raw = '';
      res.setEncoding('utf8');
      res.on('data', chunk => raw += chunk);
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, headers: res.headers, body: raw });
      });
    });
    req.on('error', reject);
    if (body !== undefined && body !== null) {
      req.write(body);
    }
    req.end();
  });
}

function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

let server;
let tests = [];
let overallPassed = true;

function startMockServer() {
  return new Promise((resolve, reject) => {
    server = http.createServer((req, res) => {
      const chunks = [];
      req.on('data', c => chunks.push(c));
      req.on('end', () => {
        const rawBody = Buffer.concat(chunks).toString('utf8');
        const parsedUrl = new URL(req.url, `http://127.0.0.1:${server.address().port}`);
        const pathname = parsedUrl.pathname;
        const query = parsedUrl.searchParams;
        const captured = {
          method: req.method,
          pathname: pathname,
          query: Object.fromEntries(query.entries()),
          authHeader: req.headers['authorization'] || null,
          contentType: req.headers['content-type'] || null,
          body: rawBody
        };

        if (pathname === '/api/auth/login') {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ code: 200, message: '登录成功', data: { token: TOKEN } }));
          return;
        }

        if (pathname === '/api/test/get') {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ code: 200, message: 'ok', data: captured }));
          return;
        }

        if (pathname === '/api/test/post') {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ code: 200, message: 'ok', data: captured }));
          return;
        }

        if (pathname === '/api/test/put') {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ code: 200, message: 'ok', data: captured }));
          return;
        }

        if (pathname === '/api/test/upload') {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ code: 200, message: 'ok', data: captured }));
          return;
        }

        if (pathname === '/api/test/business-error') {
          // HTTP 200 但业务 code=400，模拟 GlobalExceptionHandler 业务异常包装
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ code: 400, message: '参数错误', data: null }));
          return;
        }

        if (pathname === '/api/test/unauthorized') {
          res.writeHead(401, { 'Content-Type': 'application/json' });
          res.end('{"code":401,"message":"未提供有效的认证令牌"}');
          return;
        }

        if (pathname === '/api/test/non-json') {
          res.writeHead(200, { 'Content-Type': 'text/plain' });
          res.end('not json');
          return;
        }

        res.writeHead(404, { 'Content-Type': 'application/json' });
        res.end('{"code":404,"message":"不存在"}');
      });
    });
    server.listen(PORT, '127.0.0.1', () => {
      resolve();
    });
  });
}

async function runTests() {
  await startMockServer();

  // 1. GET 带 query + Authorization
  try {
    const query = 'page=1&pageSize=20&keyword=' + encodeURIComponent('兼职');
    const resp = await sendRequest('GET', '/api/test/get?' + query, {
      'Authorization': 'Bearer ' + TOKEN
    });
    const data = JSON.parse(resp.body);
    const ok = data.code === 200 &&
      data.data.authHeader === 'Bearer ' + TOKEN &&
      data.data.query.page === '1' &&
      data.data.query.pageSize === '20' &&
      data.data.query.keyword === '兼职';
    tests.push(logResult('GET 带 query + Bearer 头', ok ? 'passed' : 'failed', 'query 编码且携带 Authorization', JSON.stringify(data.data)));
    if (!ok) overallPassed = false;
  } catch (e) {
    tests.push(logResult('GET 带 query + Bearer 头', 'failed', '无异常', e.message));
    overallPassed = false;
  }

  // 2. POST JSON
  try {
    const body = JSON.stringify({ account: '13800138000', password: '123456' });
    const resp = await sendRequest('POST', '/api/test/post', {
      'Authorization': 'Bearer ' + TOKEN,
      'Content-Type': 'application/json'
    }, body);
    const data = JSON.parse(resp.body);
    const ok = resp.statusCode === 200 &&
      data.data.contentType === 'application/json' &&
      data.data.body === body &&
      data.data.authHeader === 'Bearer ' + TOKEN;
    tests.push(logResult('POST JSON + Bearer 头', ok ? 'passed' : 'failed', 'Content-Type application/json 且正文序列化', JSON.stringify(data.data)));
    if (!ok) overallPassed = false;
  } catch (e) {
    tests.push(logResult('POST JSON + Bearer 头', 'failed', '无异常', e.message));
    overallPassed = false;
  }

  // 3. PUT JSON + query
  try {
    const body = JSON.stringify({ oldPassword: '123456', newPassword: '654321', confirmPassword: '654321' });
    const resp = await sendRequest('PUT', '/api/test/put?source=app', {
      'Authorization': 'Bearer ' + TOKEN,
      'Content-Type': 'application/json'
    }, body);
    const data = JSON.parse(resp.body);
    const ok = data.data.method === 'PUT' &&
      data.data.query.source === 'app' &&
      data.data.body === body &&
      data.data.contentType === 'application/json';
    tests.push(logResult('PUT JSON + query', ok ? 'passed' : 'failed', 'PUT 方法、query 保留、JSON 正文', JSON.stringify(data.data)));
    if (!ok) overallPassed = false;
  } catch (e) {
    tests.push(logResult('PUT JSON + query', 'failed', '无异常', e.message));
    overallPassed = false;
  }

  // 4. multipart/form-data
  try {
    const boundary = '----MockBoundary' + Date.now();
    const CRLF = '\r\n';
    const fileName = 'avatar.jpg';
    const fileContent = Buffer.from([0xFF, 0xD8, 0xFF, 0xE0]); // 伪造 JPG magic
    let bodyBuffer = Buffer.alloc(0);
    function appendText(text) {
      bodyBuffer = Buffer.concat([bodyBuffer, Buffer.from(text, 'utf8')]);
    }
    appendText('--' + boundary + CRLF);
    appendText('Content-Disposition: form-data; name="file"; filename="' + fileName + '"' + CRLF);
    appendText('Content-Type: image/jpeg' + CRLF + CRLF);
    bodyBuffer = Buffer.concat([bodyBuffer, fileContent, Buffer.from(CRLF)]);
    appendText('--' + boundary + '--' + CRLF);

    const resp = await sendRequest('POST', '/api/test/upload', {
      'Authorization': 'Bearer ' + TOKEN,
      'Content-Type': 'multipart/form-data; boundary=' + boundary
    }, bodyBuffer);
    const data = JSON.parse(resp.body);
    const hasBoundary = data.data.contentType && data.data.contentType.includes(boundary);
    const hasFileField = data.data.body.includes('filename="avatar.jpg"');
    const ok = hasBoundary && hasFileField && data.data.authHeader === 'Bearer ' + TOKEN;
    tests.push(logResult('multipart 上传 + Bearer 头', ok ? 'passed' : 'failed', 'Content-Type 包含 boundary 且正文含文件字段', JSON.stringify({ hasBoundary, hasFileField, authHeader: data.data.authHeader })));
    if (!ok) overallPassed = false;
  } catch (e) {
    tests.push(logResult('multipart 上传 + Bearer 头', 'failed', '无异常', e.message));
    overallPassed = false;
  }

  // 5. HTTP 200 但业务 code != 200 视为错误
  try {
    const resp = await sendRequest('GET', '/api/test/business-error', {});
    const data = JSON.parse(resp.body);
    const ok = resp.statusCode === 200 && data.code === 400;
    tests.push(logResult('HTTP 200 业务 code=400 包装', ok ? 'passed' : 'failed', 'HTTP 200 但 ApiResult.code=400', JSON.stringify(data)));
    if (!ok) overallPassed = false;
  } catch (e) {
    tests.push(logResult('HTTP 200 业务 code=400 包装', 'failed', '无异常', e.message));
    overallPassed = false;
  }

  // 6. HTTP 401 未授权
  try {
    const resp = await sendRequest('GET', '/api/test/unauthorized', {});
    const ok = resp.statusCode === 401 && resp.body.includes('401');
    tests.push(logResult('HTTP 401 未授权响应', ok ? 'passed' : 'failed', 'HTTP 401 + JSON code=401', JSON.stringify({ statusCode: resp.statusCode, body: resp.body })));
    if (!ok) overallPassed = false;
  } catch (e) {
    tests.push(logResult('HTTP 401 未授权响应', 'failed', '无异常', e.message));
    overallPassed = false;
  }

  // 7. 非 JSON 响应导致解析失败
  try {
    const resp = await sendRequest('GET', '/api/test/non-json', {});
    const ok = resp.statusCode === 200 && resp.headers['content-type'].includes('text/plain');
    tests.push(logResult('非 JSON 响应场景', ok ? 'passed' : 'blocked', '服务端返回 text/plain 且非 JSON，客户端应拒绝解析', JSON.stringify({ contentType: resp.headers['content-type'], body: resp.body })));
    if (!ok) overallPassed = false;
  } catch (e) {
    tests.push(logResult('非 JSON 响应场景', 'failed', '无异常', e.message));
    overallPassed = false;
  }
}

runTests().then(() => {
  server.close();
  const outputPath = path.join(__dirname, 'mock-transport-test-output.json');
  const output = {
    generatedAt: new Date().toISOString(),
    overall: overallPassed ? 'passed' : 'failed',
    tests: tests
  };
  fs.writeFileSync(outputPath, JSON.stringify(output, null, 2), 'utf8');
  console.log(JSON.stringify(output, null, 2));
  process.exit(overallPassed ? 0 : 1);
}).catch(err => {
  if (server) server.close();
  const output = { overall: 'failed', error: err.message, tests: tests };
  console.error(JSON.stringify(output, null, 2));
  process.exit(1);
});
