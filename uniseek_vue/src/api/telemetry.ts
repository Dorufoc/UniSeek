import request from './index'

// ==================== 类型定义 ====================

/** 最新遥测数据（温度 / 湿度） */
export interface TelemetryLatest {
  temperature?: number
  humidity?: number
}

// ==================== 私有工具 ====================

/**
 * 将后端返回解包为 TelemetryLatest，缺失或非数字字段视为 undefined。
 * 该守卫保证 UI 只处理确定类型的数字，避免 NaN 或非法值污染 KPI。
 */
function parseTelemetryLatest(value: unknown): TelemetryLatest {
  if (typeof value !== 'object' || value === null) {
    return {}
  }
  const obj = value as Record<string, unknown>
  return {
    temperature: typeof obj.temperature === 'number' ? obj.temperature : undefined,
    humidity: typeof obj.humidity === 'number' ? obj.humidity : undefined
  }
}

// ==================== 遥测 API ====================

/**
 * 获取最新环境遥测数据。
 * _silent 用于抑制失败提示、错误页跳转等非侵入式 UI 行为。
 */
export async function getLatestTelemetry(): Promise<TelemetryLatest> {
  const config: Record<string, unknown> = { _silent: true }
  const res: unknown = await request.get('/v1/telemetry/latest', config)
  return parseTelemetryLatest(res)
}
