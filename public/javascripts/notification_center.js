/*
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#-- 
*/

var NotificationCenterManager = function(name) {
    this.name = name;
    this.observers = {};

    // Adds an observer to be triggered by the +identifier+
    // +receiver+ is the object on which +callback+ will be bound to
    // +sender+ is the object who holds the observer (usually you'd
    // pass in this)
    // +senderArguments+ is a list of arguments to passed to the
    // +callback+.
    // The +callback+ will receive the +sender+ as argument, as well
    // as any +senderArguments+.
    this.addObserver = function(identifier, receiver, callback) {
        if (!(this.observers[identifier] instanceof Array))
            this.observers[identifier] = [];
        this.observers[identifier].push({
            'receiver': receiver,
            'callback': callback
        });
    };

    // notify observers for the +identifier+ event, that +sender+ has
    // triggered it 
    this.notifyObservers = function(identifier, sender, runtimeArgs) {
        var observers = this.observers[identifier];
        if (!observers)
            return false;

        jQuery.each(observers, function() {
            var args = jQuery.makeArray(runtimeArgs);
            this.callback.apply(this.receiver, args);
        });

        return true;
    };

    // remove all observers associated with +identifier+
    this.removeAllObservers = function(identifier) {
        delete this.observers[identifier];
    };

    // remove the observer that +sender+ has initiated for
    // +identifier+
    this.removeObserver = function(identifier, receiver) {
        var observers = this.observers[identifier];
        if (!observers)
            return false;
        wasDeleted = false;
        observers.each(function(index) {
            if (this.receiver === receiver) {
                observers.splice(index, 1);
                wasDeleted = true;
            }
        });
        return wasDeleted;
    };
};

var NotificationCenter = new NotificationCenterManager("default notification center");