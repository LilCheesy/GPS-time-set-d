package com.carebrigde.backjavaspring.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class SosResponse {
    private Long facilityId;
    private String facilityName;
    private String facilityAddress;
    private String phone;
    private String facilityType;
    private Double destLatitude;
    private Double destLongitude;
    private Double distanceMeters;
    private Integer estimatedMinutes;
    private String status;
    private Map<String, String> zMetadata;
}
