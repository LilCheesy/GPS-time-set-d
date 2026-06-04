package com.carebrigde.backjavaspring.repository;

import com.carebrigde.backjavaspring.entity.UserHomeProfile;
import org.locationtech.jts.geom.Point;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface UserHomeProfileRepository extends JpaRepository<UserHomeProfile, Long> {

    @Query(value = """
        SELECT h FROM UserHomeProfile h
        WHERE h.userId = :userId
        AND ST_DWithin(
            h.homeLocation,
            ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
            :radiusMeters
        )
        LIMIT 1
        """)
    UserHomeProfile findHomeWithinRadius(
            @Param("userId") Long userId,
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusMeters") Integer radiusMeters
    );
}
