require "google/cloud/firestore"
firestore = Google::Cloud::Firestore.new project_id: "today-a7e8e"
items = firestore.collection 'Items'
query = items.where("completed", "=", true).where("date", ">", Time.now)
query.get {|x| puts "x: #{x.class}, #{x.document_id}"}
