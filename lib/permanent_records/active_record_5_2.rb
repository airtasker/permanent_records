module HandlePermanentRecordsDestroyedInBelongsToAssociation
  def handle_dependency
    return unless load_target

    case options[:dependent]
    when :destroy
      target.destroy
      if target.respond_to?(:soft_destroyed?)
        raise ActiveRecord::Rollback unless target.soft_destroyed?
      elsif target.respond_to?(:destroyed?)
        raise ActiveRecord::Rollback unless target.destroyed?
      else
        raise ActiveRecord::Rollback unless target.deleted?
      end
    else
      target.send(options[:dependent])
    end
  end
end

module HandlePermanentRecordsDestroyedInHasOneAssociation
  def delete(method = options[:dependent])
    if load_target
      case method
      when :delete
        target.delete
      when :destroy
        target.destroyed_by_association = reflection
        target.destroy
        if target.respond_to?(:soft_destroyed?)
          throw(:abort) unless target.soft_destroyed?
        elsif target.respond_to?(:destroyed?)
          throw(:abort) unless target.destroyed?
        else
          throw(:abort) unless target.deleted?
        end
      when :nullify
        target.update_columns(reflection.foreign_key => nil) if target.persisted?
      end
    end
  end
end

ActiveRecord::Associations::BelongsToAssociation.prepend HandlePermanentRecordsDestroyedInBelongsToAssociation
ActiveRecord::Associations::HasOneAssociation.prepend HandlePermanentRecordsDestroyedInHasOneAssociation
