module Zimbra
  class SearchDirectory
    class << self
      def all
        SearchDirectoryService.all
      end
      
      def find_by_name(name)
        SearchDirectoryService.get_by_name(name)
      end
    end
  end
  
  class SearchDirectoryService < HandsoapService
    def get_by_name(name, type = :accounts)
      xml = invoke("n2:SearchDirectoryRequest") do |message|
        Builder.get_by_name(message, name, type)
      end
      return nil if soap_fault_not_found?
      Parser.get_all_response(xml)
    end

    class Builder
      class << self
        def get_by_name(message, name, type)
          message.set_attr 'domain', name        
          message.set_attr 'types', "distributionlists,accounts"
          message.add 'query'
        end
      end
    end

    
    class Parser
      class << self
        def get_all_response(response)
          result = {}

          result[:accounts] = (response/"//n2:account").map do |node|
            account_response(node)
          end

          result[:lists] = (response/"//n2:dl").map { |i| distribution_list_response(i) }         

          result
        end

        def distribution_list_response(node)
          id = (node/'@id').to_s
          name = (node/'@name').to_s

          members = (node/"n2:a[@n='zimbraMailForwardingAddress']").map { |x| x.to_s }

          Zimbra::DistributionList.new(
                                       :id => id,
                                       :name => name,
                                       :members => members)
        end

        
        def account_response(node)
          id = (node/'@id').to_s
          name = (node/'@name').to_s
          acls = Zimbra::ACL.read(node)
          cos_id = Zimbra::A.read(node, 'zimbraCOSId')
          delegated_admin = Zimbra::A.read(node, 'zimbraIsDelegatedAdminAccount')
          Zimbra::Account.new(:id => id, :name => name, :acls => acls, :cos_id => cos_id, :delegated_admin => delegated_admin)
        end
      end
    end
  end
end
