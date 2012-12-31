class Ability
  include CanCan::Ability

  def initialize(user)
    can :read, :all
    if user.nil?
      can :create, User
    elsif user.admin?
      can :manage, :all
    else
      can [:destroy, :update], User do |u|
        u == user
      end
      can :share, Record do |record|
        record.user_id == user.id
      end
      can :create, Comment
      can :create, Shout
      can :destroy, Comment do |comment|
        comment.user_id == user.id
      end
      cannot :read, Puzzle
    end
  end
end
