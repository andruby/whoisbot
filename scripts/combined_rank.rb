require 'csv'

tlds = {}

CSV.foreach("research/tld_google_estimates.csv", headers: true) do |row|
  tld = row["tld"]
  tlds[tld] ||= {}
  tlds[tld]["google_estimate_count"] = row["google estimated count"].to_i
end

rank = 0
tlds.sort_by { |tld, data| data["google_estimate_count"] }.reverse.each do |tld, data|
  tlds[tld]["google_rank"] = (rank+=1)
end

CSV.foreach("research/tld_top_1m.csv") do |row|
  tld = row.first
  tlds[tld] ||= {}
  tlds[tld]["1m_sites"] = row.last.to_i
end

rank = 0
tlds.sort_by { |tld, data| data["1m_sites"] || 0 }.reverse.each do |tld, data|
  tlds[tld]["alexa_rank"] = (rank+=1)
end

tlds.each do |tld, data|
  rank1 = data["google_rank"]
  rank2 = data["alexa_rank"]
  combined_score = if rank1 && rank2
    (rank1 * rank2) ** (0.5)
  elsif rank1
    rank1
  elsif rank2
    rank2
  end
  tlds[tld]["combined_score"] = combined_score
end

rank = 0
tlds.sort_by { |tld, data| data["combined_score"] }.each do |tld, data|
  tlds[tld]["combined_rank"] = (rank+=1)
end

puts "writing to research/tld_combined.csv"
CSV.open("research/tld_combined.csv", "w") do |row|
  row << ["tld", "combined_rank", "google_rank", "alexa_rank", "combined_score", "google_estimate", "1m_sites"]
  tlds.each do |tld, data|
    row << [tld, data["combined_rank"], data["google_rank"], data["alexa_rank"], data["combined_score"], data["google_estimate_count"], data["1m_sites"]]
  end
end
