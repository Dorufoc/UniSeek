package com.uniseek.dto;

import lombok.Data;

import javax.validation.constraints.NotNull;
import java.time.LocalDateTime;

/**
 * 更新投递状态请求 DTO
 */
@Data
public class UpdateStatusRequest {

    /** 目标状态 */
    @NotNull(message = "状态不能为空")
    private Integer status;

    /** 面试时间 */
    private LocalDateTime interviewTime;

    /** 面试地点 */
    private String interviewLocation;

    /** 淘汰原因 */
    private String rejectReason;

    /** HR 备注 */
    private String hrNote;
}
