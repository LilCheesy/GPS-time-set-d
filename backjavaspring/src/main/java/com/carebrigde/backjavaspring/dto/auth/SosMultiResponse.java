package com.carebrigde.backjavaspring.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data @Builder @NoArgsConstructor @AllArgsConstructor
public class SosMultiResponse {
    private String status;
    private List<FacilityInfo> facilities;
    private Map<String, String> zMetadata;
}
