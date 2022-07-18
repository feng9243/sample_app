class User < ApplicationRecord
    has_many :microposts, dependent: :destroy
    attr_accessor :remember_token, :activation_token, :reset_token
    before_save :downcase_email
    before_create :create_activation_digest   
    validates :name, presence: true, length: { maximum: 50 }
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    validates :email, presence: true, length: { maximum: 255 },
                      format: { with: VALID_EMAIL_REGEX },
                      uniqueness: { case_sensitive: false }
    has_secure_password
    validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
    
    def self.digest(string)
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                    BCrypt::Engine.cost
        BCrypt::Password.create(string, cost: cost) 
    end

    def feed
        Micropost.where("user_id = ?", id) 
    end

    # 返回一个随机令牌 
    def self.new_token
        SecureRandom.urlsafe_base64 
    end

    def remember
        self.remember_token = User.new_token
        update_attribute(:remember_digest, User.digest(remember_token))
    end

    def authenticated?(remember_token)
        return false if remember_digest.nil?
        BCrypt::Password.new(remember_digest).is_password?(remember_token)  
    end

    # 忘记用户
    def forget
        update_attribute(:remember_digest, nil) 
    end

    # 如果密码重设请求超时了，返回 true 
    def password_reset_expired?
        reset_sent_at < 2.hours.ago 
    end

    # 激活账户
    def activate
       update_columns(activated: true, activated_at: Time.zone.now)
    end

    # 发送激活邮件
    def send_activation_email
        UserMailer.account_activation(self).deliver_now 
    end
    
    # 设置密码重设相关的属性 
    def create_reset_digest
        self.reset_token = User.new_token
        update_attribute(:reset_digest,  User.digest(reset_token))
        update_attribute(:reset_sent_at, Time.zone.now)
    end

    # 发送密码重设邮件
    def send_password_reset_email
        UserMailer.password_reset(self).deliver_now 
    end

    # 把电子邮件地址转换成小写 
    def downcase_email
        self.email = email.downcase end
    # 创建并赋值激活令牌和摘要 

    def create_activation_digest
        self.activation_token  = User.new_token
        self.activation_digest = User.digest(activation_token)
    end

    def authenticated?(attribute, token)
        digest = send("#{attribute}_digest")
        return false if digest.nil? 
        BCrypt::Password.new(digest).is_password?(token)
    end

end
