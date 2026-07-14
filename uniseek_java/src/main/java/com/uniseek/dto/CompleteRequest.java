package com.uniseek.dto;

import lombok.Data;

import java.math.BigDecimal;

/**
 * 结算确认请求 DTO
 */
@Data
public class CompleteRequest {

    /** 结算金额 */
    private BigDecimal settlementAmount;

    /** HR 备注 */
    private String hrNote;
}
