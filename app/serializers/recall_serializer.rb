module RecallSerializer
  module_function

  def call(recall)
    {
      campaignNumber: recall.campaign_number,
      manufacturer: recall.manufacturer,
      component: recall.component,
      summary: recall.summary,
      consequence: recall.consequence,
      remedy: recall.remedy,
      reportedOn: recall.reported_on,
      parkIt: recall.park_it,
      parkOutside: recall.park_outside
    }
  end
end
