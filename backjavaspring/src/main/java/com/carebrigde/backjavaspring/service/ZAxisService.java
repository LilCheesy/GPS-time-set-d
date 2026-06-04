package com.carebrigde.backjavaspring.service;

import com.carebrigde.backjavaspring.entity.UserHomeProfile;
import com.carebrigde.backjavaspring.repository.UserHomeProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class ZAxisService {

    private final UserHomeProfileRepository homeRepository;

    private static final int HOME_DETECTION_RADIUS_METERS = 50;

    public Map<String, String> extractZMetadata(Long userId, Double lat, Double lng) {
        UserHomeProfile home = homeRepository.findHomeWithinRadius(
                userId, lat, lng, HOME_DETECTION_RADIUS_METERS
        );

        if (home == null) {
            return null;
        }

        Map<String, String> metadata = new HashMap<>();
        if (home.getFloorNumber() != null && !home.getFloorNumber().isEmpty()) {
            metadata.put("floorNumber", home.getFloorNumber());
        }
        if (home.getRoomNumber() != null && !home.getRoomNumber().isEmpty()) {
            metadata.put("roomNumber", home.getRoomNumber());
        }
        metadata.put("addressLabel", home.getAddressLabel());
        metadata.put("locationType", "HOME");
        return metadata;
    }
}
