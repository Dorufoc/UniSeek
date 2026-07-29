// extract-arkts-surface.js
// 只读扫描 uniseek_arkts/entry/src/main/ets，生成 ArkTS 页面与 Service 全量调用清单。
// 运行：node .omo/audit/arkts-api/scripts/extract-arkts-surface.js

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..', '..', '..');
const ARKTS_ROOT = path.join(ROOT, 'uniseek_arkts', 'entry', 'src', 'main', 'ets');
const MAIN_PAGES_JSON = path.join(ROOT, 'uniseek_arkts', 'entry', 'src', 'main', 'resources', 'base', 'profile', 'main_pages.json');
const OUTPUT_FILE = path.join(ROOT, '.omo', 'audit', 'arkts-api', 'arkts-surface.json');

function relativeEts(filePath) {
  return path.relative(ARKTS_ROOT, filePath).replace(/\\/g, '/');
}

function walkDir(dir, pattern = /.*/) {
  const results = [];
  if (!fs.existsSync(dir)) return results;
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...walkDir(fullPath, pattern));
    } else if (entry.isFile() && pattern.test(entry.name)) {
      results.push(fullPath);
    }
  }
  return results.sort();
}

function readLines(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  // 统一换行符便于行号计算
  return content.replace(/\r\n/g, '\n').split('\n');
}

function extractImports(line) {
  const imports = [];

  // 具名/默认/命名空间导入：import { a, b } from 'module' / import X from 'module' / import * as ns from 'module'
  const namedRegex = /import\s+(?:(\*\s+as\s+\w+)|(\w+)|\{([^}]*)\})?\s*from\s+['"]([^'"]+)['"]/g;
  // side-effect 导入：import 'module'
  const sideEffectRegex = /import\s+['"]([^'"]+)['"]\s*;?/g;

  let m;
  while ((m = namedRegex.exec(line)) !== null) {
    const moduleName = m[4];
    if (!moduleName) continue;
    const names = [];
    if (m[1]) names.push(m[1].replace(/\s+/g, ' ').trim());
    if (m[2]) names.push(m[2].trim());
    if (m[3]) {
      m[3].split(',').forEach(n => {
        const clean = n.trim();
        if (clean) names.push(clean);
      });
    }
    imports.push({ moduleName, names });
  }

  while ((m = sideEffectRegex.exec(line)) !== null) {
    imports.push({ moduleName: m[1], names: [] });
  }

  return imports;
}

function extractExports(lines) {
  const exports = [];
  const seen = new Set();
  lines.forEach((line, idx) => {
    // 跳过注释行，避免误判
    const trimmed = line.trim();
    if (trimmed.startsWith('//') || trimmed.startsWith('*') || trimmed.startsWith('/*')) return;

    const patterns = [
      /export\s+(?:abstract\s+)?class\s+(\w+)/,
      /export\s+interface\s+(\w+)/,
      /export\s+type\s+(\w+)/,
      /export\s+(?:async\s+)?function\s+(\w+)/,
      /export\s+const\s+(\w+)\s*[:=]/,
      /export\s+let\s+(\w+)\s*[:=]/,
      /export\s+var\s+(\w+)\s*[:=]/,
      /export\s+default\s+(?:class|interface|function)?\s*(\w+)?/,
      /export\s+\{([^}]*)\}/
    ];
    for (const re of patterns) {
      const m = line.match(re);
      if (m) {
        if (m[1]) {
          const key = `${idx + 1}:${m[1]}`;
          if (!seen.has(key)) {
            seen.add(key);
            exports.push({ name: m[1], kind: guessKind(re), line: idx + 1 });
          }
        } else if (re.source.includes('\\{')) {
          const list = m[1].split(',').map(s => s.trim()).filter(Boolean);
          list.forEach(raw => {
            const name = raw.split(' as ')[0].trim();
            const key = `${idx + 1}:${name}`;
            if (!seen.has(key)) {
              seen.add(key);
              exports.push({ name, kind: 'reexport', line: idx + 1 });
            }
          });
        } else {
          const key = `${idx + 1}:default`;
          if (!seen.has(key)) {
            seen.add(key);
            exports.push({ name: 'default', kind: 'default', line: idx + 1 });
          }
        }
      }
    }
  });
  return exports;
}

function guessKind(re) {
  if (re.source.includes('class')) return 'class';
  if (re.source.includes('interface')) return 'interface';
  if (re.source.includes('type\s+')) return 'type';
  if (re.source.includes('function')) return 'function';
  if (re.source.includes('const')) return 'const';
  if (re.source.includes('let')) return 'let';
  if (re.source.includes('var')) return 'var';
  return 'unknown';
}

function classifyRouteLiteral(value) {
  // WebSocket 事件名
  if (/^(NEW_MESSAGE|SEND_ACK|PING|PONG|MESSAGE_READ|ERROR)$/.test(value)) return 'websocket-event';
  // WebSocket URL
  if (/^wss?:\/\//.test(value)) return 'websocket-url';
  // 上传路由：以 /api/upload/ 开头、包含 /upload-attachment、/files/ 或多段文件上传路径
  if (/^\/api\/upload\//.test(value)
    || /\/upload-attachment/.test(value)
    || /\/files?\//.test(value)
    || /\/multipart/.test(value)) return 'upload-route';
  // REST 路由：以 /api/ 或 /ws/ 开头的服务端路径
  if (/^\/(?:api|ws)\//.test(value)) return 'rest-route';
  return 'unknown';
}

function extractRouteLiterals(filePath, lines) {
  const routes = [];
  const rel = relativeEts(filePath);

  // 只捕获类似服务端路由/URL 的字符串字面量：
  // 1. /api/... 或 /ws/... 路径
  // 2. ws:// 或 wss:// URL
  const routeRe = /['"]((?:\/(?:api|ws)\/[^'"\s]*)|(?:ws[s]?:\/\/[^'"\s]+))['"]/g;
  // WebSocket 协议事件名
  const eventRe = /['"](NEW_MESSAGE|SEND_ACK|PING|PONG|MESSAGE_READ|ERROR)['"]/g;

  const seen = new Set();

  function addRoute(lineNo, value, kind) {
    const key = `${rel}:${lineNo}:${value}:${kind}`;
    if (seen.has(key)) return;
    seen.add(key);
    routes.push({
      file: rel,
      line: lineNo,
      value,
      kind
    });
  }

  lines.forEach((line, idx) => {
    const lineNo = idx + 1;
    const trimmed = line.trim();
    if (trimmed.startsWith('//')) return;

    let m;
    // 路由字面量
    routeRe.lastIndex = 0;
    while ((m = routeRe.exec(line)) !== null) {
      const value = m[1];
      addRoute(lineNo, value, classifyRouteLiteral(value));
    }
    // WebSocket 事件名
    eventRe.lastIndex = 0;
    while ((m = eventRe.exec(line)) !== null) {
      addRoute(lineNo, m[1], 'websocket-event');
    }
  });

  return routes;
}

function extractApiClientCalls(lines) {
  const calls = [];
  const re = /ApiClient\.(get|post|put|putWithParams|patch|delete|searchTasks)\s*[<(]/g;
  lines.forEach((line, idx) => {
    let m;
    while ((m = re.exec(line)) !== null) {
      calls.push({ method: m[1], line: idx + 1 });
    }
  });
  return calls;
}

function extractServiceMethods(lines) {
  const methods = [];
  const re = /(?:static\s+|async\s+)?(?:static\s+async\s+|async\s+)?(\w+)\s*\([^)]*\)\s*[:{]/g;
  // 简单扫描类中的方法声明
  lines.forEach((line, idx) => {
    const trimmed = line.trim();
    if (trimmed.startsWith('//')) return;
    let m;
    while ((m = re.exec(line)) !== null) {
      const name = m[1];
      if (['if', 'while', 'for', 'switch', 'catch', 'return'].includes(name)) continue;
      methods.push({ name, line: idx + 1 });
    }
  });
  return methods;
}

function extractPropsAndEvents(lines) {
  const props = [];
  const events = [];
  // @Prop / @Link / @Local / @Param / @State / @Provide / @Consume 声明
  const decoratorRe = /@(?:Prop|Link|Local|Param|State|Provide|Consume)\s+(\w+)\s*:\s*([^=:=\n]+)/g;
  // 回调入参类型，形如 callback: () => void / onEvent: (x: T) => void
  const callbackRe = /(\w+)\s*:\s*\([^)]*\)\s*=>\s*\w+/g;
  lines.forEach((line, idx) => {
    let m;
    decoratorRe.lastIndex = 0;
    while ((m = decoratorRe.exec(line)) !== null) {
      props.push({ name: m[1].trim(), line: idx + 1 });
    }
    callbackRe.lastIndex = 0;
    while ((m = callbackRe.exec(line)) !== null) {
      const name = m[1].trim();
      if (name.startsWith('on') || name.includes('Callback') || name.includes('callback')) {
        events.push({ name, line: idx + 1 });
      }
    }
  });
  return { props, events };
}

function isServiceImport(moduleName) {
  return moduleName.includes('/services/') || moduleName.startsWith('./services/') || moduleName.startsWith('../services/');
}

function isComponentImport(moduleName) {
  return moduleName.includes('/components/') || moduleName.startsWith('./components/') || moduleName.startsWith('../components/');
}

function isLocalOnlyService(filePath, routes) {
  // 没有任何 REST/上传/WebSocket 实际服务端通信的 service 视为 local-only
  return routes.length === 0;
}

function parseFile(filePath) {
  const lines = readLines(filePath);
  const rel = relativeEts(filePath);
  const imports = [];
  const exports = extractExports(lines);
  const routes = extractRouteLiterals(filePath, lines);
  const apiClientCalls = extractApiClientCalls(lines);
  const serviceMethods = extractServiceMethods(lines);
  const { props, events } = extractPropsAndEvents(lines);

  lines.forEach((line, idx) => {
    const lineImports = extractImports(line);
    for (const imp of lineImports) {
      imports.push({ ...imp, line: idx + 1 });
    }
  });

  const usedServices = imports
    .filter(i => isServiceImport(i.moduleName))
    .map(i => ({
      moduleName: i.moduleName,
      names: i.names,
      line: i.line
    }));

  const usedComponents = imports
    .filter(i => isComponentImport(i.moduleName))
    .map(i => ({
      moduleName: i.moduleName,
      names: i.names,
      line: i.line
    }));

  return {
    path: rel,
    imports,
    exports,
    routes,
    apiClientCalls,
    serviceMethods,
    props,
    events,
    usedServices,
    usedComponents,
    lineCount: lines.length
  };
}

function main() {
  const startTime = new Date().toISOString();

  const mainPages = JSON.parse(fs.readFileSync(MAIN_PAGES_JSON, 'utf-8'));
  const registeredSrc = mainPages.src || [];

  const pagesFiles = walkDir(path.join(ARKTS_ROOT, 'pages'), /\.ets$/);
  const componentsFiles = walkDir(path.join(ARKTS_ROOT, 'components'), /\.ets$/);
  const servicesFiles = walkDir(path.join(ARKTS_ROOT, 'services'), /\.ets$/);
  const commonFiles = walkDir(path.join(ARKTS_ROOT, 'common'), /\.ets$/);

  const allEtsFiles = [...pagesFiles, ...componentsFiles, ...servicesFiles, ...commonFiles];
  const pagesByRel = new Map(allEtsFiles.map(p => [relativeEts(p), p]));

  // registeredPages 标注是否对应 .ets 文件存在
  // main_pages.json 的 src 已经是 pages/XXX 形式，直接追加 .ets 即可
  const registeredPages = registeredSrc.map(srcPath => {
    const candidate = `${srcPath}.ets`;
    const exists = pagesByRel.has(candidate);
    return {
      src: srcPath,
      expectedFile: candidate,
      fileExists: exists
    };
  });

  const pages = pagesFiles.map(parseFile);
  const components = componentsFiles.map(parseFile);
  const services = servicesFiles.map(parseFile);
  const commonModules = commonFiles.map(parseFile);

  const unregistered = pages
    .filter(p => !registeredSrc.some(src => `${src}.ets` === p.path))
    .map(p => p.path);

  const localOnlyServices = services
    .filter(s => isLocalOnlyService(s.path, s.routes))
    .map(s => ({
      path: s.path,
      reason: '无 REST 路由、上传路由或 WebSocket 调用'
    }));

  const routeLiterals = [];
  for (const group of [pages, components, services, commonModules]) {
    for (const file of group) {
      for (const r of file.routes) {
        routeLiterals.push({
          file: r.file,
          line: r.line,
          value: r.value,
          kind: r.kind,
          containingGroup: file.path.startsWith('services/') ? 'service'
            : file.path.startsWith('pages/') ? 'page'
              : file.path.startsWith('components/') ? 'component' : 'common'
        });
      }
    }
  }

  const issues = [];

  // 未解析的 import：存在 import 语法但模块名为空或动态
  for (const file of [...pages, ...components, ...services, ...commonModules]) {
    for (const imp of file.imports) {
      if (!imp.moduleName || imp.moduleName.includes('${')) {
        issues.push({
          type: 'unresolved-import',
          file: file.path,
          line: imp.line,
          detail: `无法解析的 import: ${imp.moduleName || '<empty>'}`
        });
      }
    }
  }

  // main_pages 中不存在对应文件的条目
  registeredPages.filter(r => !r.fileExists).forEach(r => {
    issues.push({
      type: 'registered-page-missing',
      src: r.src,
      expectedFile: r.expectedFile
    });
  });

  const outOfArktsScope = commonModules.map(m => ({
    path: m.path,
    exports: m.exports.map(e => ({ name: e.name, kind: e.kind, line: e.line })),
    summary: 'ArkTS 本地工具/策略/样式模块，无服务端调用'
  }));

  const output = {
    meta: {
      baseline: 'baseline-pending',
      generatedAt: startTime,
      mainPagesJson: relativeEts(MAIN_PAGES_JSON).replace(/\.ets$/, '.json'),
      counts: {
        registeredPages: registeredPages.length,
        pages: pages.length,
        components: components.length,
        services: services.length,
        commonModules: commonModules.length,
        routeLiterals: routeLiterals.length,
        unregisteredPages: unregistered.length,
        localOnlyServices: localOnlyServices.length,
        outOfArktsScope: outOfArktsScope.length
      }
    },
    registeredPages,
    pages,
    components,
    services,
    commonModules,
    outOfArktsScope,
    unregistered,
    localOnlyServices,
    routeLiterals,
    issues
  };

  fs.mkdirSync(path.dirname(OUTPUT_FILE), { recursive: true });
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(output, null, 2), 'utf-8');
  console.log(`已生成：${OUTPUT_FILE}`);
  console.log(`注册页面：${registeredPages.length} 个，页面文件：${pages.length} 个，组件：${components.length} 个，服务：${services.length} 个`);
}

main();
