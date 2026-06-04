package com.carebrigde.backjavaspring.service;

import com.carebrigde.backjavaspring.dto.auth.SosRequest;
import com.carebrigde.backjavaspring.dto.auth.SosResponse;
import com.carebrigde.backjavaspring.entity.MedicalFacility;
import com.carebrigde.backjavaspring.repository.MedicalFacilityRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class SosService {

    private final MedicalFacilityRepository facilityRepository;
    private final ZAxisService zAxisService;

    private static final int SEARCH_RADIUS_METERS = 5000;
    private static final int MAX_RESULTS = 1;
    private static final double AVERAGE_SPEED_KMH = 30.0;

    public SosResponse processSos(SosRequest request) {
        List<MedicalFacility> facilities = facilityRepository.findNearestFacilities(
                request.getLatitude(),
                request.getLongitude(),
                SEARCH_RADIUS_METERS,
                MAX_RESULTS
        );

        if (facilities.isEmpty()) {
            return SosResponse.builder()
                    .status("NO_FACILITY_FOUND")
                    .build();
        }

        MedicalFacility nearest = facilities.get(0);
        double distanceKm = calculateHaversineDistance(
                request.getLatitude(), request.getLongitude(),
                nearest.getLatitude(), nearest.getLongitude()
        );
        int estimatedMinutes = (int) Math.ceil(
                (distanceKm / AVERAGE_SPEED_KMH) * 60
        );

        Map<String, String> zMetadata = null;
        if (request.getUserId() != null) {
            zMetadata = zAxisService.extractZMetadata(
                    request.getUserId(),
                    request.getLatitude(),
                    request.getLongitude()
            );
        }

        return SosResponse.builder()
                .facilityId(nearest.getId())
                .facilityName(nearest.getName())
                .facilityAddress(nearest.getAddress())
                .phone(nearest.getPhone())
                .facilityType(nearest.getFacilityType())
                .destLatitude(nearest.getLatitude())
                .destLongitude(nearest.getLongitude())
                .distanceMeters(Math.round(distanceKm * 1000.0) / 1000.0)
                .estimatedMinutes(estimatedMinutes)
                .status("SUCCESS")
                .zMetadata(zMetadata != null ? zMetadata : Collections.emptyMap())
                .build();
    }

    private double calculateHaversineDistance(double lat1, double lng1, double lat2, double lng2) {
        final int R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
