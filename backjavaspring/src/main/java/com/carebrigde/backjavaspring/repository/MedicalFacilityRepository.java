package com.carebrigde.backjavaspring.repository;

import com.carebrigde.backjavaspring.entity.MedicalFacility;
import org.locationtech.jts.geom.Point;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MedicalFacilityRepository extends JpaRepository<MedicalFacility, Long> {

    @Query(value = """
        SELECT f FROM MedicalFacility f
        WHERE f.isActive = true
        AND ST_DWithin(
            f.location,
            ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
            :radiusMeters
        )
        ORDER BY f.location <-> ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)
        LIMIT :limit
        """)
    List<MedicalFacility> findNearestFacilities(
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusMeters") Integer radiusMeters,
            @Param("limit") Integer limit
    );
}
