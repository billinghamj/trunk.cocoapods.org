Sequel.migration do
  change do
    create_table(:owners, :ignore_index_errors=>true) do
      primary_key :id
      String :email, :size=>255, :null=>false
      String :name, :size=>255, :null=>false
      DateTime :created_at
      DateTime :updated_at
      
      index [:email], :unique=>true
    end
    
    create_table(:pods, :ignore_index_errors=>true) do
      primary_key :id
      String :name, :size=>255, :null=>false
      DateTime :created_at, :null=>false
      DateTime :updated_at
      
      index [:name], :unique=>true
    end
    
    #create_table(:schema_info) do
      #Integer :version, :default=>0, :null=>false
    #end
    
    create_table(:owners_pods) do
      foreign_key :owner_id, :owners, :key=>[:id]
      foreign_key :pod_id, :pods, :key=>[:id]
    end
    
    create_table(:sessions, :ignore_index_errors=>true) do
      primary_key :id
      String :token, :size=>255, :null=>false
      String :verification_token, :size=>255, :null=>false
      TrueClass :verified, :default=>false, :null=>false
      DateTime :valid_until, :null=>false
      DateTime :created_at
      DateTime :updated_at
      foreign_key :owner_id, :owners, :null=>false, :key=>[:id]
      
      index [:token], :unique=>true
      index [:verification_token], :unique=>true
    end
    
    create_table(:log_messages) do
      primary_key :id
      String :message, :text=>true, :null=>false
      DateTime :created_at
      DateTime :updated_at
      Integer :submission_job_id, :null=>false
    end
    
    create_table(:pod_versions, :ignore_index_errors=>true) do
      primary_key :id
      String :name, :size=>255, :null=>false
      TrueClass :published, :default=>false, :null=>false
      String :commit_sha, :size=>255
      DateTime :created_at
      DateTime :updated_at
      foreign_key :pod_id, :pods, :null=>false, :key=>[:id]
      Integer :published_by_submission_job_id
      
      index [:pod_id, :name], :unique=>true
    end
    
    create_table(:submission_jobs) do
      primary_key :id
      String :specification_data, :text=>true, :null=>false
      TrueClass :succeeded
      String :commit_sha, :size=>255
      DateTime :created_at
      DateTime :updated_at
      foreign_key :pod_version_id, :pod_versions, :null=>false, :key=>[:id]
      foreign_key :owner_id, :owners, :null=>false, :key=>[:id]
    end
    
    alter_table(:log_messages) do
      add_foreign_key [:submission_job_id], :submission_jobs, :name=>:log_messages_submission_job_id_fkey, :key=>[:id]
    end
    
    alter_table(:pod_versions) do
      add_foreign_key [:published_by_submission_job_id], :submission_jobs, :name=>:pod_versions_published_by_submission_job_id_fkey, :key=>[:id]
    end
  end
end