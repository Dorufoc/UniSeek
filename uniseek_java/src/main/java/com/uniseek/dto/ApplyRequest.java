package com.uniseek.dto;

import lombok.Data;

import javax.validation.constraints.NotNull;

/**
 * 投递请求 DTO
 */
@Data
public class ApplyRequest {

    /** 职位 ID */
    @NotNull(message = "职位ID不能为空")
    private Long taskId;
}
