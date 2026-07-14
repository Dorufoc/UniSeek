package com.uniseek.service;

import com.uniseek.entity.OperationLog;

/**
 * 操作日志服务接口
 */
public interface OperationLogService {

    /**
     * 保存操作日志
     */
    void saveLog(OperationLog operationLog);
}
