import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.Statement;

public class FixPostgis {
    public static void main(String[] args) {
        try {
            Connection conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/gps_demo", "postgres", "Hanoiditconmemay123@");
            Statement stmt = conn.createStatement();
            stmt.execute("CREATE EXTENSION IF NOT EXISTS postgis;");
            System.out.println("SUCCESS: PostGIS created in gps_demo");
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
