class TargetRevisionService
   def revision_exists?(external_id,revision_id)
       TargetRevision.find_by(external_id: external_id, revision_id: revision_id)
   end

   def latest_revision(external_id)
      TargetRevision.where(external_id: external_id).last
   end

   def add_revision(details)
      TargetRevision.create(details)
   end
end