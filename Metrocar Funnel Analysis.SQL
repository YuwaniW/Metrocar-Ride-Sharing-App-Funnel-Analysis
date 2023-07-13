WITH user_ride_status AS (
SELECT user_id
FROM ride_requests
GROUP BY user_id
),

total_users AS (
SELECT
  a.platform AS platform,
  s.age_range AS age_range,
  a.download_ts::DATE AS download_date,
  COUNT(DISTINCT a.*) AS number_of_users_app_downloaded,
  COUNT(DISTINCT s.user_id) AS total_unique_users_signup,
  COUNT(DISTINCT urs.user_id) AS total_users_ride_requested,
  COUNT(DISTINCT r.ride_id) AS number_of_rides_requested,
  COUNT(DISTINCT CASE WHEN r.accept_ts IS NOT NULL THEN r.user_id END) AS rides_accepted_by_driver_user_wise,
  COUNT(DISTINCT CASE WHEN accept_ts IS NOT NULL THEN r.ride_id END) AS rides_accepted_by_driver,
  COUNT(DISTINCT CASE WHEN r.dropoff_ts IS NOT NULL THEN r.user_id END) AS unique_users_completed_ride,
  COUNT(DISTINCT CASE WHEN dropoff_ts IS NOT NULL THEN r.ride_id END) AS completed_rides,
  COUNT(DISTINCT CASE WHEN t.charge_status = 'Approved' THEN r.user_id END) AS number_of_users_complete_payments,
  COUNT(DISTINCT CASE WHEN t.charge_status = 'Approved' THEN r.ride_id END) AS number_of_rides_complete_payments,
  COUNT(DISTINCT re.user_id) AS number_of_users_provide_reviews,
  COUNT(DISTINCT re.ride_id) AS number_of_rides_received_reviews
FROM app_downloads AS a
LEFT JOIN signups AS s ON a.app_download_key = s.session_id
LEFT JOIN user_ride_status AS urs ON s.user_id = urs.user_id
LEFT JOIN ride_requests AS r ON s.user_id = r.user_id
LEFT JOIN transactions AS t ON t.ride_id = r.ride_id
LEFT JOIN reviews AS re ON re.user_id = s.user_id
--WHERE s.age_range IS NOT NULL
GROUP BY platform, age_range,download_date
),

funnel_steps AS (
  SELECT
    1 AS funnel_step,
    'Downloads' AS funnel_name,
    platform,
    age_range,
    download_date,
    CAST(number_of_users_app_downloaded AS BIGINT) AS user_count,
    CAST(NULL AS BIGINT) AS ride_count
  FROM total_users

  UNION

  SELECT
    2 AS funnel_step,
    'Sign_UP' AS funnel_name,
    platform,
    age_range,
    download_date,
    CAST(total_unique_users_signup AS BIGINT) AS user_count,
    CAST(NULL AS BIGINT) AS ride_count
  FROM total_users

  UNION 

  SELECT
    3 AS funnel_step,
    'Ride_Requested' AS funnel_name,
     platform,
     age_range,
     download_date,
    CAST(total_users_ride_requested AS BIGINT) AS user_count,
    CAST(number_of_rides_requested AS BIGINT) AS ride_count
  FROM total_users

  UNION

  SELECT
    4 AS funnel_step,
    'Ride_Accepted' AS funnel_name,
     platform,
     age_range,
     download_date,
    CAST(rides_accepted_by_driver_user_wise AS BIGINT) AS user_count,
    CAST(rides_accepted_by_driver AS BIGINT) AS ride_count
  FROM total_users

  UNION 

  SELECT
    5 AS funnel_step,
    'Ride_Completed' AS funnel_name,
     platform,
     age_range,
     download_date,
    CAST(unique_users_completed_ride AS BIGINT) AS user_count,
    CAST(completed_rides AS BIGINT) AS ride_count
  FROM total_users

  UNION  

  SELECT
    6 AS funnel_step,
    'Payment' AS funnel_name,
    platform,
    age_range,
    download_date,
    CAST(number_of_users_complete_payments AS BIGINT) AS user_count,
    CAST(number_of_rides_complete_payments AS BIGINT) AS ride_count
  FROM total_users

  UNION

  SELECT
    7 AS funnel_step,
    'Review' AS funnel_name,
    platform,
    age_range,
    download_date,
    CAST(number_of_users_provide_reviews AS BIGINT) AS user_count,
    CAST(number_of_rides_received_reviews AS BIGINT) AS ride_count
  FROM total_users  
)
 
SELECT *
FROM funnel_steps
ORDER BY funnel_steps ASC;









