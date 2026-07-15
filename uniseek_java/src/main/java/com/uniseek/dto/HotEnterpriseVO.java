package com.uniseek.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class HotEnterpriseVO {

    private Long id;
    private String companyName;
    private String industry;
    private Long regionId;
    private String regionName;
    private String description;
    private BigDecimal heatScore;
    private Long activeJobCount;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getIndustry() {
        return industry;
    }

    public void setIndustry(String industry) {
        this.industry = industry;
    }

    public Long getRegionId() {
        return regionId;
    }

    public void setRegionId(Long regionId) {
        this.regionId = regionId;
    }

    public String getRegionName() {
        return regionName;
    }

    public void setRegionName(String regionName) {
        this.regionName = regionName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public BigDecimal getHeatScore() {
        return heatScore;
    }

    public void setHeatScore(BigDecimal heatScore) {
        this.heatScore = heatScore;
    }

    public Long getActiveJobCount() {
        return activeJobCount;
    }

    public void setActiveJobCount(Long activeJobCount) {
        this.activeJobCount = activeJobCount;
    }
}
