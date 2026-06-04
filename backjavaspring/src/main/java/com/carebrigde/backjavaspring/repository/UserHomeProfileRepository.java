package com.carebrigde.backjavaspring.repository;

import com.carebrigde.backjavaspring.entity.UserHomeProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface UserHomeProfileRepository extends JpaRepository<UserHomeProfile, Long> {

    @Query(value = """
        SELECT * FROM user_home_profiles h
        WHERE h.user_id = :userId
        AND ST_DWithin(
            h.home_location::geography,
            ST_SetSRID(ST_MakePoint(:lng, :lat), 4326)::geography,
            :radiusMeters
        )
        LIMIT 1
        """, nativeQuery = true)
    UserHomeProfile findHomeWithinRadius(
            @Param("userId") Long userId,
            @Param("lat") Double lat,
            @Param("lng") Double lng,
            @Param("radiusMeters") Integer radiusMeters
    );
}
