module Zimbra
  class DistributionList
    class << self
      def all
        DistributionListService.all
      end

      def find_by_id(id)
        DistributionListService.get_by_id(id)
      end

      def find_by_name(name)
        DistributionListService.get_by_name(name)
      end

      def create(name)
        DistributionListService.create(name)
      end

      def acl_name
        'grp'
      end
    end

    attr_accessor :id, :name, :members
    #:admin_console_ui_components, :admin_group

    def initialize(options = {})
      options.each { |name, value| self.send("#{name}=", value) }
      @original_members = self.members.dup
    end

    def members
      @members ||= []
    end

    def new_members
      self.members - @original_members
    end

    def removed_members
      @original_members - self.members
    end

    def delete
      DistributionListService.delete(self)
    end

    def save
      DistributionListService.modify(self)
    end
  end

  class DistributionListService < HandsoapService
    def all
      xml = invoke("n2:GetAllDistributionListsRequest")
      Parser.get_all_response(xml)
    end

    def get_by_id(id)
      xml = invoke("n2:GetDistributionListRequest") do |message|
        Builder.get_by_id(message, id)
      end
      return nil if soap_fault_not_found?
      Parser.distribution_list_response(xml/'//n2:dl')
    end

    def get_by_name(name)
      xml = invoke("n2:GetDistributionListRequest") do |message|
        Builder.get_by_name(message, name)
      end
      return nil if soap_fault_not_found?
      Parser.distribution_list_response(xml/'//n2:dl')
    end

    def create(name)
      xml = invoke("n2:CreateDistributionListRequest") do |message|
        Builder.create(message, name)
      end
      Parser.distribution_list_response(xml/'//n2:dl')
    end

    def modify(dist)
      xml = invoke("n2:ModifyDistributionListRequest") do |message|
        Builder.modify(message, dist)
      end
      Parser.distribution_list_response(xml/'//n2:dl')

      modify_members(dist)
    end 

    def modify_members(distribution_list)
      distribution_list.new_members.each do |member|
        add_member(distribution_list, member)
      end
      distribution_list.removed_members.each do |member|
        remove_member(distribution_list, member)
      end
    end

    def add_member(distribution_list, member)
      xml = invoke("n2:AddDistributionListMemberRequest") do |message|
        Builder.add_member(message, distribution_list.id, member)
      end
    end

    def remove_member(distribution_list, member)
      xml = invoke("n2:RemoveDistributionListMemberRequest") do |message|
        Builder.remove_member(message, distribution_list.id, member)
      end
    end

    def delete(dist)
      xml = invoke("n2:DeleteDistributionListRequest") do |message|
        Builder.delete(message, dist.id)
      end
    end

    module Builder
      class << self
        def create(message, name)
          message.add 'name', name
        end

        def get_by_id(message, id)
          message.add 'dl', id do |d|
            d.set_attr 'by', 'id'
          end
        end

        def get_by_name(message, name)
          message.add 'dl', name do |d|
            d.set_attr "by", 'name'
          end
        end

        def modify(message, distribution_list)
          message.add 'id', distribution_list.id
          modify_attributes(message, distribution_list)
        end

        def modify_attributes(message, distribution_list)
        end

        def add_member(message, distribution_list_id, member)
          message.add 'id', distribution_list_id
          message.add 'dlm', member
        end

        def remove_member(message, distribution_list_id, member)
          message.add 'id', distribution_list_id
          message.add 'dlm', member
        end

        def delete(message, id)
          message.add 'id', id
        end
      end
    end
    module Parser
      class << self
        def get_all_response(response)
          items = response/"//n2:dl"
          items.map { |i| distribution_list_response(i) }
        end

        def distribution_list_response(node)
          id = (node/'@id').to_s
          name = (node/'@name').to_s
          members = (node/"//n2:dlm").map { |n| n.to_s }

          Zimbra::DistributionList.new(:id => id, :name => name,
            :members => members)
        end
      end
    end
  end
end
