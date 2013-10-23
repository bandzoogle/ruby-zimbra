module Zimbra
  class Account
    class << self
      def all
        AccountService.all
      end

      def find_by_id(id)
        AccountService.get_by_id(id)
      end

      def find_by_name(name)
        AccountService.get_by_name(name)
      end

      def create(options)
        account = new(options)
        AccountService.create(account) 
      end

      def acl_name
        'account'
      end
    end

    attr_accessor :id, :name, :display_name, :password, :acls, :cos_id, :delegated_admin, :aliases, :forwarding

    def initialize(options = {})
      self.id = options[:id]
      self.name = options[:name]
      self.display_name = options[:display_name]
      self.password = options[:password]
      self.acls = options[:acls] || []
      self.cos_id = (options[:cos] ? options[:cos].id : options[:cos_id])
      self.delegated_admin = options[:delegated_admin]
      self.aliases = options[:aliases] || []
      self.forwarding = options[:forwarding]
    end

    def delegated_admin=(val)
      @delegated_admin = Zimbra::Boolean.read(val) 
    end
    def delegated_admin?
      @delegated_admin
    end

    def save
      AccountService.modify(self)
    end

    def delete
      AccountService.delete(self)
    end
  end

  class AccountService < HandsoapService
    def all
      xml = invoke("n2:GetAllAccountsRequest")
      Parser.get_all_response(xml)
    end

    def create(account)
      xml = invoke("n2:CreateAccountRequest") do |message|
        Builder.create(message, account)
      end
      Parser.account_response(xml/"//n2:account")
    end

    def get_by_id(id)
      xml = invoke("n2:GetAccountRequest") do |message|
        Builder.get_by_id(message, id)
      end
      return nil if soap_fault_not_found?
      Parser.account_response(xml/"//n2:account")
    end

    def get_by_name(name)
      xml = invoke("n2:GetAccountRequest") do |message|
        Builder.get_by_name(message, name)
      end
      return nil if soap_fault_not_found?
      Parser.account_response(xml/"//n2:account")
    end

    def modify(account)
      xml = invoke("n2:ModifyAccountRequest") do |message|
        Builder.modify(message, account)
      end
      Parser.account_response(xml/'//n2:account')
    end 

    def delete(dist)
      xml = invoke("n2:DeleteAccountRequest") do |message|
        Builder.delete(message, dist.id)
      end
    end

    class Builder
      class << self
        def create(message, account)
          message.add 'name', account.name
          message.add 'password', account.password
          A.inject(message, 'zimbraCOSId', account.cos_id)
        end
        
        def get_by_id(message, id)
          message.add 'account', id do |c|
            c.set_attr 'by', 'id'
          end
        end

        def get_by_name(message, name)
          message.add 'account', name do |c|
            c.set_attr 'by', 'name'
          end
        end

        def modify(message, account)
          message.add 'id', account.id
          if account.password.present?
            message.add 'password', account.password
          end

          modify_attributes(message, account)
        end
        def modify_attributes(message, account)
          if account.acls.empty?
            ACL.delete_all(message)
          else
            account.acls.each do |acl|
              acl.apply(message)
            end
          end
          Zimbra::A.inject(message, 'zimbraCOSId', account.cos_id)
          Zimbra::A.inject(message, 'zimbraIsDelegatedAdminAccount', (account.delegated_admin? ? 'TRUE' : 'FALSE'))
        end

        def delete(message, id)
          message.add 'id', id
        end
      end
    end
    class Parser
      class << self
        def get_all_response(response)
          (response/"//n2:account").map do |node|
            account_response(node)
          end
        end

        def account_response(node)
          id = (node/'@id').to_s
          name = (node/'@name').to_s
          acls = Zimbra::ACL.read(node)
          cos_id = Zimbra::A.read(node, 'zimbraCOSId')

          tmp = (node/"n2:a[@n='mail']")

          display_name = Zimbra::A.read(node, 'displayName')
          forwarding = Zimbra::A.read(node, 'zimbraPrefMailForwardingAddress')
          
          aliases = tmp.collect { |t| t.to_s }.reject { |e| e == name }
          
          delegated_admin = Zimbra::A.read(node, 'zimbraIsDelegatedAdminAccount')
          Zimbra::Account.new(:id => id, :name => name, :display_name => display_name, :acls => acls, :cos_id => cos_id, :delegated_admin => delegated_admin, :aliases => aliases, :forwarding => forwarding)
        end
      end
    end
  end
end
