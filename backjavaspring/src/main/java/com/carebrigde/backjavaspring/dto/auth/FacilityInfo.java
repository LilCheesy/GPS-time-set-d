package com.carebrigde.backjavaspring.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class FacilityInfo {
    private Long facilityId;
    private String facilityName;
    private String facilityAddress;
    private String phone;
    private String facilityType;
    private Double destLatitude;
    private Double destLongitude;
    private Double distanceMeters;
    private Integer estimatedMinutes;
}
